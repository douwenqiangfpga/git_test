# =========================================================
# pds_run.tcl
# =========================================================

# 通过脚本文件位置反推工程根目录
set SCRIPT_DIR [file normalize [file dirname [info script]]]
set ROOT_DIR   [file normalize "$SCRIPT_DIR/.."]

set RTL_DIR    [file normalize "$ROOT_DIR/rtl"]
set IP_DIR     [file normalize "$ROOT_DIR/ip"]
set CONSTR_DIR [file normalize "$ROOT_DIR/constr"]

set FAMILY_NAME  "Logos"
set DEVICE_NAME  "PGL50G"
set SPEED_GRADE  "-6"
set PACKAGE_NAME "FBG484"

puts "========================================================="
puts "PDS implementation flow"
puts "========================================================="
puts "SCRIPT_DIR   = $SCRIPT_DIR"
puts "ROOT_DIR     = $ROOT_DIR"
puts "RTL_DIR      = $RTL_DIR"
puts "IP_DIR       = $IP_DIR"
puts "CONSTR_DIR   = $CONSTR_DIR"
puts ""

puts "Add RTL design files..."
add_design "$RTL_DIR/led.v"
add_design "$RTL_DIR/spwm_deadtime_insert.v"
add_design "$RTL_DIR/spwm_single_top.v"
add_design "$RTL_DIR/top.v"
puts ""

puts "Add IP files..."
add_design "$IP_DIR/PLL_IP/PLL_IP.idf"
add_design "$IP_DIR/spwm_sine_lut_256_u12/spwm_sine_lut_256_u12.idf"
puts ""

puts "Add constraint files..."
add_constraint -fdc "$CONSTR_DIR/spwm.fdc"
puts ""

puts "Set target architecture..."
set_arch \
    -family $FAMILY_NAME \
    -device $DEVICE_NAME \
    -speedgrade $SPEED_GRADE \
    -package $PACKAGE_NAME
puts ""

puts "Run compile..."
compile
puts ""

puts "Run synthesize..."
synthesize -ads
puts ""

puts "Run device mapping..."
dev_map
puts ""

puts "Run place and route..."
pnr
puts ""

puts "Generate timing report..."
report_timing
puts ""

puts "Generate bitstream..."
gen_bit_stream
puts ""

puts "========================================================="
puts "PDS flow finished."
puts "========================================================="