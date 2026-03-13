# =========================================================
# run_sim.tcl
# 用途：
#   通过 ModelSim 启动 40U/SPWM 工程的最小功能仿真。
#
# 当前仿真入口：
#   tb/tb_top.v
#
# 当前 DUT 顶层：
#   rtl/top.v
#
# 模块层级关系：
#   tb_top
#     -> top
#        -> PLL_IP
#        -> led
#        -> spwm_single_top
#           -> spwm_deadtime_insert
#           -> spwm_sine_lut_256_u12
#              -> ipml_rom_v1_7_spwm_sine_lut_256_u12
#              -> ipml_spram_v1_7_spwm_sine_lut_256_u12
#              -> spwm_sine_lut_256_u12_init_param
#
# 说明：
#   1. prj/ 为 IDE 生成工程目录，不作为当前仿真脚本依赖输入。
#   2. 仿真依赖厂商库 usim，其中 PLL_IP.v 依赖 GTP_PLL_E3。
#   3. tb_top.v 中使用了 GTP_GRS，因此 vsim 启动时需要带上 usim.GTP_GRS。
#   4. 当前脚本依赖 sim.bat 先切换到 script/ 目录。
#
# 当前最小仿真文件清单：
#   ip/PLL_IP/PLL_IP.v
#
#   ip/spwm_sine_lut_256_u12/rtl/ipml_spram_v1_7_spwm_sine_lut_256_u12.v
#   ip/spwm_sine_lut_256_u12/rtl/ipml_rom_v1_7_spwm_sine_lut_256_u12.v
#   ip/spwm_sine_lut_256_u12/rtl/spwm_sine_lut_256_u12_init_param.v
#   ip/spwm_sine_lut_256_u12/spwm_sine_lut_256_u12.v
#
#   rtl/led.v
#   rtl/spwm_deadtime_insert.v
#   rtl/spwm_single_top.v
#   rtl/top.v
#
#   tb/tb_top.v
#
# 编译顺序原则：
#   1. 先编 IP 底层依赖文件
#   2. 再编 IP 顶层封装
#   3. 再编 RTL 模块
#   4. 最后编 testbench
# =========================================================

transcript on
onerror {resume}


# 读取本机环境配置
source ./env.tcl


# =========================================================
# # 路径定义（依赖 sim.bat 已先切到 script 目录）
# =========================================================

# 直接用当前工作目录作为 script 目录
set SCRIPT_DIR [pwd]
set ROOT_DIR   [file normalize "$SCRIPT_DIR/.."]

set IP_DIR     [file normalize "$ROOT_DIR/ip"]
set RTL_DIR    [file normalize "$ROOT_DIR/rtl"]
set TB_DIR     [file normalize "$ROOT_DIR/tb"]

# =========================================================
# 删除并重建 work 库
# =========================================================
if {[file exists "$SCRIPT_DIR/work"]} {
    file delete -force "$SCRIPT_DIR/work"
}

cd $SCRIPT_DIR
vlib work
vmap work work

# 厂商仿真库映射：路径按你的本机实际修改
vmap usim $USIM_LIB

puts "SCRIPT_DIR = $SCRIPT_DIR"
puts "ROOT_DIR   = $ROOT_DIR"
puts "IP_DIR     = $IP_DIR"
puts "RTL_DIR    = $RTL_DIR"
puts "TB_DIR     = $TB_DIR"
puts "USIM_LIB   = $USIM_LIB"

# =========================================================
# 编译 IP 文件
# =========================================================
vlog -sv "$IP_DIR/PLL_IP/PLL_IP.v"

vlog -sv "$IP_DIR/spwm_sine_lut_256_u12/rtl/ipml_spram_v1_7_spwm_sine_lut_256_u12.v"
vlog -sv "$IP_DIR/spwm_sine_lut_256_u12/rtl/ipml_rom_v1_7_spwm_sine_lut_256_u12.v"
vlog -sv "$IP_DIR/spwm_sine_lut_256_u12/rtl/spwm_sine_lut_256_u12_init_param.v"
vlog -sv "$IP_DIR/spwm_sine_lut_256_u12/spwm_sine_lut_256_u12.v"

vlog -sv "$IP_DIR/mul_ip/mul_ip.v"
vlog -sv "$IP_DIR/mul_ip/rtl/ipml_mult_v1_3_mul_ip.v"

# =========================================================
# 编译 RTL 文件
# =========================================================
vlog -sv "$RTL_DIR/led.v"
vlog -sv "$RTL_DIR/spwm_deadtime_insert.v"
vlog -sv "$RTL_DIR/spwm_single_top.v"
vlog -sv "$RTL_DIR/top.v"

# =========================================================
# 编译 Testbench
# =========================================================
vlog -sv "$TB_DIR/tb_top.v"

# =========================================================
# 启动仿真
# =========================================================
vsim -voptargs=+acc -L usim work.tb_top usim.GTP_GRS

# 如果你后面有 wave.do，可以打开这一句
do wave.do

run -all