# =========================================================
# create_project.tcl
# 功能：
#   创建一个 PDS 测试工程，并导入 RTL / TB / 约束 / IP
# 说明：
#   建议先用测试工程名，不要直接覆盖正式工程
# =========================================================

# ---------------------------------------------------------
# 基本信息
# ---------------------------------------------------------
set PROJECT_NAME "spwm_test"
set TOP_NAME     "top"
set FAMILY_NAME  "Logos"
set DEVICE_NAME  "PGL50G"
set PACKAGE_NAME "FBG484"
set SPEED_GRADE  "-6"

# ---------------------------------------------------------
# 路径定义（依赖从 scripts/ 目录执行）
# ---------------------------------------------------------
set SCRIPT_DIR [pwd]
set ROOT_DIR   [file normalize "$SCRIPT_DIR/.."]

set PRJ_ROOT   [file normalize "$ROOT_DIR/prj"]
set RTL_DIR    [file normalize "$ROOT_DIR/rtl"]
set TB_DIR     [file normalize "$ROOT_DIR/tb"]
set IP_DIR     [file normalize "$ROOT_DIR/ip"]
set CONSTR_DIR [file normalize "$ROOT_DIR/constr"]

set PRJ_DIR      [file normalize "$PRJ_ROOT/$PROJECT_NAME"]
set PROJECT_FILE [file normalize "$PRJ_DIR/$PROJECT_NAME.pds"]

# ---------------------------------------------------------
# 打印信息
# ---------------------------------------------------------
puts "========================================================="
puts "Create PDS project"
puts "========================================================="
puts "PROJECT_NAME = $PROJECT_NAME"
puts "TOP_NAME     = $TOP_NAME"
puts "FAMILY_NAME  = $FAMILY_NAME"
puts "DEVICE_NAME  = $DEVICE_NAME"
puts "PACKAGE_NAME = $PACKAGE_NAME"
puts "SPEED_GRADE  = $SPEED_GRADE"
puts ""
puts "SCRIPT_DIR   = $SCRIPT_DIR"
puts "ROOT_DIR     = $ROOT_DIR"
puts "PRJ_ROOT     = $PRJ_ROOT"
puts "RTL_DIR      = $RTL_DIR"
puts "TB_DIR       = $TB_DIR"
puts "IP_DIR       = $IP_DIR"
puts "CONSTR_DIR   = $CONSTR_DIR"
puts "PRJ_DIR      = $PRJ_DIR"
puts "PROJECT_FILE = $PROJECT_FILE"
puts ""

# ---------------------------------------------------------
# 只保证 prj/ 根目录存在
# 不要提前创建 PRJ_DIR，让 create_project 自己建
# ---------------------------------------------------------
if {![file exists $PRJ_ROOT]} {
    puts "Create project root directory:"
    puts "  $PRJ_ROOT"
    file mkdir $PRJ_ROOT
} else {
    puts "Project root directory already exists:"
    puts "  $PRJ_ROOT"
}

# ---------------------------------------------------------
# 如果测试工程目录已存在，则直接退出，避免冲突
# ---------------------------------------------------------
if {[file exists $PRJ_DIR]} {
    puts "ERROR: Project directory already exists:"
    puts "  $PRJ_DIR"
    puts "Please delete it manually before re-create."
} else {
    puts ""
    puts "Create project..."

    create_project \
        -family $FAMILY_NAME \
        -device $DEVICE_NAME \
        -package $PACKAGE_NAME \
        -speedgrade $SPEED_GRADE \
        $PROJECT_FILE

    puts ""
    puts "Open project..."
    open_project $PROJECT_FILE

    puts ""
    puts "Add design sources..."
    add_design -design $RTL_DIR/led.v
    add_design -design $RTL_DIR/spwm_deadtime_insert.v
    add_design -design $RTL_DIR/spwm_single_top.v
    add_design -design $RTL_DIR/top.v

    puts ""
    puts "Add simulation sources..."
    add_sources -simulation $TB_DIR

    puts ""
    puts "Add constraint sources..."
    add_sources -constraint $CONSTR_DIR

    puts ""
    puts "Add IP sources..."
    add_sources -ip -sub_directories $IP_DIR

    puts ""
    puts "========================================================="
    puts "Project creation flow finished."
    puts "========================================================="
}