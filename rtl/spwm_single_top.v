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
    localparam integer PHASE_STEP =   'd2147484;//(2^PHASE_ACC_W)*50/100K
    // 调制比：0 ~ (2^MOD_W - 1) 对应 0~约1.0
    localparam integer MOD_INDEX    =   'd2048;
    localparam integer CARRIER_MAX = PWM_PERIOD_CNT - 1;

    localparam integer MID_CNT     = PWM_PERIOD_CNT / 2; // 中点计数（约等于 MAX/2）

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

            // 无停顿中心对齐三角，顶点处 update
            if (!carrier_dir) begin
                if (carrier_cnt == CARRIER_MAX[CARRIER_W-1:0]) begin
                    carrier_dir <= 1'b1;
                    carrier_cnt <= carrier_cnt - 1'b1;
                    update_tick <= 1'b1;     // 最大值处更新
                end else begin
                    carrier_cnt <= carrier_cnt + 1'b1;
                end
            end else begin
                if (carrier_cnt == {CARRIER_W{1'b0}}) begin
                    carrier_dir <= 1'b0;
                    carrier_cnt <= carrier_cnt + 1'b1;
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

    spwm_sine_lut_256_u12 u_sine_lut (
      .addr(lut_addr),          // input [9:0]
      .clk(i_clk),            // input
      .rst(!i_rst_n),            // input
      .rd_data(sine_u)     // output [11:0]
    );

    //============================================================
    // 4) ✅ 中点对齐的双极性正弦实现（关键改动在这里）
    //
    // sine_u: 0..4095, center=2048
    // sin_bip0: -2048..+2047
    // sin_scaled = sin_bipolar * MOD_INDEX / 4096
    // ref = MID_CNT + sin_scaled
    // clamp to 0..CARRIER_MAX
    
    //============================================================
  localparam integer MOD_SHIFT   = 12;               // b=12 -> /4096
  localparam integer NORM_SHIFT  = MOD_SHIFT + 11;   // 再 /2048 -> >>24

  // ---------- Stage0: latch inputs ----------
  reg        v0;
  reg signed [12:0] sin_bip0;
  reg [11:0] mod0;
  reg [9:0]  mid0;          // MID_CNT=250 fits 10b
  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      v0 <= 1'b0;
      sin_bip0 <= 'd0;
      mod0 <= 'd0;
      mid0 <= 'd0;
    end else begin
      v0 <= update_tick;
      if (update_tick) begin
        sin_bip0 <= $signed({1'b0, sine_u}) - 13'sd2048;// -2048..+2047
        mod0     <= MOD_INDEX;
        mid0     <= MID_CNT[9:0];
      end
    end
  end

    // ---------- Stage1: prod1 = sin_bip0 * mod0 ----------
    wire        v1;
    wire signed [24:0] prod1;     // 13x12 -> 25
    mul_ip u_mul1 (
      .a(sin_bip0),        // input [12:0]
      .b(mod0),        // input [11:0]
      .clk(i_clk),    // input
      .rst(!i_rst_n),    // input
      .ce(v0),      // input
      .p(prod1)         // output [24:0]
    );

    // v1 = v0 延迟3拍，对齐 prod1
    reg [2:0] v0_d;
    always @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) v0_d <= 3'b000;
      else v0_d <= {v0_d[1:0], v0};
    end
    assign v1 = v0_d[2];

    // ---------- Stage2：常数乘 MID=250（用移位加减，易过时序） ----------
    // 250 = 256 - 4 - 2
    // prod_mid = prod1*256 - prod1*4 - prod1*2
    reg        v2;
    reg signed [33:0] prod_mid; // 25bit * 8bit 常数后，留足位宽（>=25+8+1）    

    always @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
        v2 <= 1'b0;
        prod_mid <= 'd0;
      end else begin
        v2 <= v1;
        if (v1) begin
          prod_mid <= ($signed(prod1) <<< 8)   // *256
                    - ($signed(prod1) <<< 2)   // - *4
                    - ($signed(prod1) <<< 1);  // - *2
        end
      end
    end

    // ---------- Stage3：归一化 + 加MID + clamp -> ref_cmp_r ----------
    reg        v3;
    reg [REF_W-1:0] ref_cmp_r;
    reg [REF_W-1:0] ref_new;
    reg signed [12:0] sin_scaled;
    reg signed [13:0] ref_s;
    always @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
        v3 <= 1'b0;
        ref_new <= 'd0;
      end else begin
        v3 <= v2;
        if (v2) begin
          // sin_scaled ≈ sin(ωt)*MID*MOD，范围约 [-MID..+MID]
          // 归一化：/4096 再 /2048 => >>>23        
          sin_scaled = $signed(prod_mid) >>> (NORM_SHIFT); // >>>23
          ref_s      = $signed(MID_CNT) + $signed(sin_scaled);    
          if (ref_s <= 0)
            ref_new <= {REF_W{1'b0}};
          else if (ref_s >= $signed(CARRIER_MAX))
            ref_new <= CARRIER_MAX[REF_W-1:0];
          else
            ref_new <= ref_s[REF_W-1:0];
        end
      end
    end

    // ---------- Stage4: compare (align carrier) ----------
    reg [CARRIER_W-1:0] carrier_d1, carrier_d2, carrier_d3;
    always @(posedge i_clk) begin
      carrier_d1 <= carrier_cnt;
      carrier_d2 <= carrier_d1;
      carrier_d3 <= carrier_d2; // 你这里延迟几拍，按 v3 相对 carrier 的延迟调整
    end

    //============================================================
    // 5) 比较器：原始SPWM
    //============================================================
    reg pwm_raw_r;

    always @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) pwm_raw_r <= 1'b0;
      else begin
          if (!i_en) pwm_raw_r <= 1'b0;
          else if (v3) ref_cmp_r <= ref_new;   // 只在更新点更新参考
          pwm_raw_r <= (ref_cmp_r > carrier_d3); // 每拍比较产生PWM
        end
    end

    assign o_pwm_raw = pwm_raw_r;
    assign o_ref_cmp = ref_cmp_r;
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