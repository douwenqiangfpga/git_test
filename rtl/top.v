module top #(
    //========================
    // 基本参数
    //========================
    parameter integer CLK_HZ         = 100_000_000, // 系统时钟，仅用于说明/注释
    parameter integer PWM_PERIOD_CNT = 500,        // 中心对齐半周期计数上限（0~PWM_PERIOD_CNT-1）
                                                   // f_pwm ≈ CLK_HZ / (2*PWM_PERIOD_CNT)

    //========================
    // LUT / DDS 参数
    //========================
    parameter integer LUT_ADDR_W     = 10,           // 1024点正弦表
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
    parameter integer DEADTIME_CYC   = 100 )          // 例如100MHz时 50cyc=500ns
    (
         input       i_clk,
         input       i_rst_n,

         output      o_pwm1/*synthesis PAP_MARK_DEBUG = "1"*/,
         output      o_pwm2/*synthesis PAP_MARK_DEBUG = "1"*/,
         output      o_pwm3/*synthesis PAP_MARK_DEBUG = "1"*/,
         output      o_pwm4/*synthesis PAP_MARK_DEBUG = "1"*/,
         //output      clkout0,
         output      o_led
   );

wire pwm_h     ;
wire pwm_l     ;
wire pll_lock  /*synthesis PAP_MARK_DEBUG = "1"*/;
wire clkout0  /*synthesis PAP_MARK_DEBUG = "1"*/;

//PLL_IP PLL_IP_inst (
//  .clkin1  (i_clk   ),        // input 50.0MHz
//  .pll_lock(pll_lock),    // output
//  .clkout0 (clkout0)       // output 100.0MHz
//);

PLL_IP PLL_IP_inst (
  .pll_rst(!i_rst_n),      // input
  .clkin1(i_clk),        // input 50.0MHz
  .pll_lock(pll_lock),    // output
  .clkout0(clkout0)       // output 25.0MHz
);

led led_inst(
    .i_clk  (clkout0),    // 100MHz
    .i_rst_n(i_rst_n),  // 低有效复位
    .o_led  (o_led)     // LED输出
);

spwm_single_top #(
   .CLK_HZ         (100_000_000), // 系统时钟，
   .PWM_PERIOD_CNT (500       ) ,// 中心对齐半周期计数上限（0~PWM_PERIOD_CNT-1）
                                                   // f_pwm ≈ CLK_HZ / (2*PWM_PERIOD_CNT)

   //========================
   // LUT / DDS 参数
   //========================
   .LUT_ADDR_W     (10   ),           // 256点正弦表
   .PHASE_ACC_W    (32  ),          // DDS相位累加器宽度

    //========================
    // 数字幅值位宽
    //========================
   .CARRIER_W      (12  ),          // 载波计数位宽（需覆盖 PWM_PERIOD_CNT）
   .MOD_W          (12  ),          // 调制比位宽（Q0.MOD_W, 满量程≈1.0）
   .SINE_W         (12  ),          // LUT输出位宽（0 ~ PWM_PERIOD_CNT-1 映射前的归一化幅值）
   .REF_W          (12  ),          // 比较参考位宽（映射到载波范围）

    //========================
    // 死区参数（时钟周期）
    //========================
   .DEADTIME_CYC   (100 )          // 例如100MHz时 50cyc=1000ns
)spwm_single_top_inst(
   .i_clk         (clkout0),
   .i_rst_n       (i_rst_n),
   .i_en          (pll_lock),
    // 输出
    .o_pwm_h      (pwm_h   ),    // 上桥臂
    .o_pwm_l      (pwm_l   )   // 下桥臂
);

assign o_pwm1 = pwm_h;
assign o_pwm2 = pwm_l;
assign o_pwm3 = pwm_l;
assign o_pwm4 = pwm_h;
endmodule