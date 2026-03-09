`timescale 1ns/1ps

module tb_top;

    //============================================================
    // 参数（仿真建议适当降频，方便更快看到结果）
    //============================================================
    localparam integer CLK_HZ         = 100_000_000; // 100MHz
    localparam integer CLK_PERIOD_NS  = 10;
    localparam integer PWM_PERIOD_CNT = 250;         // 仿真用小一些 -> f_pwm ≈ 100M/(2*250)=200kHz
    localparam integer PHASE_ACC_W    = 32;
    localparam integer LUT_ADDR_W     = 8;
    localparam integer CARRIER_W      = 12;
    localparam integer MOD_W          = 12;
    localparam integer SINE_W         = 12;
    localparam integer REF_W          = 12;
    localparam integer DEADTIME_CYC   = 100;           // 仿真缩短死区，便于看

    //============================================================
    // 信号
    //============================================================
    reg                      i_clk;
    reg                      i_rst_n;
    reg                      i_en;
    reg  [PHASE_ACC_W-1:0]   i_phase_step;
    reg  [MOD_W-1:0]         i_mod_index;

    wire                     o_pwm_raw;
    wire                     o_pwm_h;
    wire                     o_pwm_l;
    wire [CARRIER_W-1:0]     o_carrier_cnt;
    wire                     o_carrier_dir;
    wire [LUT_ADDR_W-1:0]    o_lut_addr;
    wire [REF_W-1:0]         o_ref_cmp;

    wire                     clkout0 ;
    wire                     o_pwm1;
    wire                     o_pwm2;
    wire                     o_pwm3;
    wire                     o_pwm4;

    assign clkout0 = u_top.PLL_IP_inst.clkout0;
    //============================================================
    // DUT
    //============================================================
    top #(
        .CLK_HZ         (CLK_HZ),
        .PWM_PERIOD_CNT (PWM_PERIOD_CNT),
        .LUT_ADDR_W     (LUT_ADDR_W),
        .PHASE_ACC_W    (PHASE_ACC_W),
        .CARRIER_W      (CARRIER_W),
        .MOD_W          (MOD_W),
        .SINE_W         (SINE_W),
        .REF_W          (REF_W),
        .DEADTIME_CYC   (DEADTIME_CYC)
    ) u_top(
         .i_clk  (i_clk)  ,
         .i_rst_n(i_rst_n),
         .o_pwm1 (o_pwm1) ,
         .o_pwm2 (o_pwm2) ,
         .o_pwm3 (o_pwm3) ,
         .o_pwm4 (o_pwm4) ,
         .o_led  ()
   );

    //============================================================
    // 时钟
    //============================================================
    initial begin
        i_clk = 1'b0;
        forever #(40/2) i_clk = ~i_clk;
    end

    //============================================================
    // 计算 phase_step 的辅助任务（仅TB）
    //
    // f_out = phase_step * f_pwm / 2^PHASE_ACC_W
    // f_pwm = CLK_HZ / (2*PWM_PERIOD_CNT)
    // => phase_step = f_out * 2^PHASE_ACC_W / f_pwm
    //============================================================
    real f_pwm_real;
    real f_out_real;
    real phase_step_real;
    integer phase_step_int;

    task set_fout_hz;
        input real fout_hz;
        begin
            f_pwm_real      = CLK_HZ * 1.0 / (2.0 * PWM_PERIOD_CNT);
            f_out_real      = fout_hz;
            phase_step_real = f_out_real * (2.0**PHASE_ACC_W) / f_pwm_real;
            phase_step_int  = $rtoi(phase_step_real);

            i_phase_step = phase_step_int[PHASE_ACC_W-1:0];

            $display("[%0t] set_fout_hz=%f, f_pwm=%f, phase_step=%0d (0x%08h)",
                     $time, f_out_real, f_pwm_real, phase_step_int, i_phase_step);
        end
    endtask

    //============================================================
    // 激励
    //============================================================
    initial begin
        i_rst_n      = 1'b0;
        i_en         = 1'b0;
        i_phase_step = {PHASE_ACC_W{1'b0}};
        i_mod_index  = 12'd0;

        #(20*CLK_PERIOD_NS);
        i_rst_n = 1'b1;

        #(20*CLK_PERIOD_NS);
        i_en = 1'b1;

        // 调制比先给 80% 左右（4095 * 0.8 ≈ 3276）
        i_mod_index = 12'd3276;

        // 设置输出正弦频率（示例：2kHz，仿真快）
        set_fout_hz(2000.0);

        // 跑一段
        #(2_000_000); // 2ms

        // 改幅值到 50%
        i_mod_index = 12'd2048;
        $display("[%0t] mod_index -> 50%%", $time);
        #(2_000_000);

        // 改频率到 5kHz
        set_fout_hz(5000.0);
        #(2_000_000);

        // 关闭输出
        i_en = 1'b0;
        #(200*CLK_PERIOD_NS);

        $display("[%0t] TB finished.", $time);
        $stop;
    end

    //============================================================
    // 简单互补保护检查（仿真断言风格）
    //============================================================
    always @(posedge clkout0) begin
        if (i_rst_n) begin
            if (o_pwm_h && o_pwm_l) begin
                $display("[%0t] ERROR: shoot-through detected! o_pwm_h && o_pwm_l == 1", $time);
                $stop;
            end
        end
    end

GTP_GRS GRS_INST
      (
          .GRS_N(1'b1)
      );

endmodule