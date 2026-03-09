`timescale 1ns/1ps

module spwm_single_top #(
    //========================
    // 基本参数
    //========================
    parameter integer CLK_HZ         = 100_000_000, // 系统时钟，
    parameter integer PWM_PERIOD_CNT = 500,        // 中心对齐半周期计数上限（0~PWM_PERIOD_CNT-1）
                                                   // f_pwm ≈ CLK_HZ / (2*PWM_PERIOD_CNT)
    //========================
    // LUT / DDS 参数
    //========================
    parameter integer LUT_ADDR_W     = 10,           // 256点正弦表
    parameter integer PHASE_ACC_W    = 32,          // DDS相位累加器宽度

    //========================
    // 数字幅值位宽
    //========================
    parameter integer CARRIER_W      = 12,          // 载波计数位宽（需覆盖 PWM_PERIOD_CNT）
    parameter integer MOD_W          = 12,          // 调制比位宽（Q0.MOD_W, 满量程≈1.0）
    parameter integer SINE_W         = 12,          // LUT输出位宽（0 ~ PWM_PERIOD_CNT-1 映射前的归一化幅值）
    parameter integer REF_W          = 12,          // 比较参考位宽（映射到载波范围）

    //========================
    // 死区参数（时钟周期）
    //========================
    parameter integer DEADTIME_CYC   = 100           // 例如100MHz时 50cyc=500ns
)(
    input  wire                      i_clk,
    input  wire                      i_rst_n,
    input  wire                      i_en,

    // 输出
    output wire                      o_pwm_h,    // 上桥臂
    output wire                      o_pwm_l     // 下桥臂
);
    // 调试观察口
    wire [CARRIER_W-1:0]      o_carrier_cnt /*synthesis PAP_MARK_DEBUG = "1"*/;
    wire                      o_carrier_dir /*synthesis PAP_MARK_DEBUG = "1"*/;
    wire [LUT_ADDR_W-1:0]     o_lut_addr    /*synthesis PAP_MARK_DEBUG = "1"*/; 
    wire [REF_W-1:0]          o_ref_cmp     /*synthesis PAP_MARK_DEBUG = "1"*/;
    wire                      o_pwm_raw     /*synthesis PAP_MARK_DEBUG = "1"*/;  // 原始SPWM（未加死区）
    //============================================================
    // 1) 中心对齐三角载波
    //============================================================
    reg [CARRIER_W-1:0] carrier_cnt/*synthesis PAP_MARK_DEBUG = "1"*/;
    reg                 carrier_dir/*synthesis PAP_MARK_DEBUG = "1"*/;   // 0: up, 1: down
    reg                 update_tick/*synthesis PAP_MARK_DEBUG = "1"*/;   // 每个PWM周期更新一次（在回到0点时打1拍）

    // DDS频率控制字
    localparam integer PHASE_STEP =   'd2147483;//(2^PHASE_ACC_W)*50/100K
    // 调制比：0 ~ (2^MOD_W - 1) 对应 0~约1.0
    localparam integer MOD_INDEX    =   'd2048;
    localparam integer CARRIER_MAX = PWM_PERIOD_CNT - 1;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            carrier_cnt <= {CARRIER_W{1'b0}};
            carrier_dir <= 1'b0; // up
            update_tick <= 1'b0;
        end else if (!i_en) begin
            carrier_cnt <= {CARRIER_W{1'b0}};
            carrier_dir <= 1'b0;
            update_tick <= 1'b0;
        end else begin
            update_tick <= 1'b0;

            if (!carrier_dir) begin
                // up count
                if (carrier_cnt == CARRIER_MAX) begin
                    carrier_dir <= 1'b1;
                    // 顶点保持1拍后下数（也可改成立即回退）
                    carrier_cnt <= carrier_cnt;
                end else begin
                    carrier_cnt <= carrier_cnt + 1'b1;
                end
            end else begin
                // down count
                if (carrier_cnt == {CARRIER_W{1'b0}}) begin
                    carrier_dir <= 1'b0;
                    carrier_cnt <= carrier_cnt;
                    update_tick <= 1'b1; // 在0点更新正弦参考（每完整PWM周期1次）
                end else begin
                    carrier_cnt <= carrier_cnt - 1'b1;
                end
            end
        end
    end

    assign o_carrier_cnt = carrier_cnt;
    assign o_carrier_dir = carrier_dir;

    //============================================================
    // 2) DDS相位累加（每个PWM周期更新一次）
    //============================================================
    reg [PHASE_ACC_W-1:0] phase_acc/*synthesis PAP_MARK_DEBUG = "1"*/;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            phase_acc <= {PHASE_ACC_W{1'b0}};
        end else if (!i_en) begin
            phase_acc <= {PHASE_ACC_W{1'b0}};
        end else if (update_tick) begin
            phase_acc <= phase_acc + PHASE_STEP;
        end
    end

    // 取高位作为LUT地址
    wire [LUT_ADDR_W-1:0] lut_addr;
    assign lut_addr = phase_acc[PHASE_ACC_W-1 -: LUT_ADDR_W]/*synthesis PAP_MARK_DEBUG = "1"*/;
    assign o_lut_addr = lut_addr;

    //============================================================
    // 3) 正弦LUT（归一化：0 ~ (2^SINE_W -1)）
    //============================================================
    wire [SINE_W-1:0] sine_u;

    //spwm_sine_lut_256_u12 u_sine_lut (
    //    .i_clk   (i_clk),
    //    .i_addr  (lut_addr),
    //    .o_data  (sine_u)
    //);

    spwm_sine_lut_256_u12 u_sine_lut (
      .addr(lut_addr),          // input [9:0]
      .clk(i_clk),            // input
      .rst(!i_rst_n),            // input
      .rd_data(sine_u)     // output [11:0]
    );

    //============================================================
    // 4) 幅值调制 + 映射到载波范围
    //
    // sine_u 是 0~(2^SINE_W-1)
    // MOD_INDEX 是 0~(2^MOD_W-1)
    //
    // 先做归一化乘法，再映射到 0~CARRIER_MAX
    //============================================================

    // 乘法位宽
    wire [SINE_W+MOD_W-1:0] mult_sine_mod/*synthesis PAP_MARK_DEBUG = "1"*/;
    assign mult_sine_mod = sine_u * MOD_INDEX;

    // 归一化到 SINE_W 位宽（等效 / (2^MOD_W)）
    wire [SINE_W-1:0] sine_mod_u/*synthesis PAP_MARK_DEBUG = "1"*/;
    assign sine_mod_u = mult_sine_mod[SINE_W+MOD_W-1 -: SINE_W]; // 截高位，简单稳定

    // 再映射到载波范围：ref_cmp = sine_mod_u * CARRIER_MAX / (2^SINE_W -1)
    // 为简化资源，这里用乘法后右移近似（当 CARRIER_MAX 接近 2^REF_W 时效果好）
    // 如果你想更准，可换成精确除法或预先把LUT直接做成载波幅值范围
    wire [SINE_W+CARRIER_W-1:0] mult_ref_map/*synthesis PAP_MARK_DEBUG = "1"*/;
    assign mult_ref_map = sine_mod_u * CARRIER_MAX[CARRIER_W-1:0];

    wire [REF_W-1:0] ref_cmp/*synthesis PAP_MARK_DEBUG = "1"*/;
    assign ref_cmp = mult_ref_map[SINE_W+CARRIER_W-1 -: REF_W];

    assign o_ref_cmp = ref_cmp;

    //============================================================
    // 5) 比较器：原始SPWM
    //============================================================
    reg pwm_raw_r;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            pwm_raw_r <= 1'b0;
        end else if (!i_en) begin
            pwm_raw_r <= 1'b0;
        end else begin
            pwm_raw_r <= (ref_cmp > carrier_cnt);
        end
    end

    assign o_pwm_raw = pwm_raw_r;

    //============================================================
    // 6) 死区 + 互补输出
    //============================================================
    spwm_deadtime_insert #(
        .DEADTIME_CYC (DEADTIME_CYC)
    ) u_deadtime (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),
        .i_en       (i_en),
        .i_pwm_in   (pwm_raw_r),
        .o_pwm_h    (o_pwm_h),
        .o_pwm_l    (o_pwm_l)
    );

endmodule