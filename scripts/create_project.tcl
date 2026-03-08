source ./env.tcl

if {[file exists $PRJ_DIR]} {
    file delete -force $PRJ_DIR
}
file mkdir $PRJ_DIR

create_project $PROJ_NAME $PRJ_DIR -device $DEVICE_NAME
set_top $TOP_NAME