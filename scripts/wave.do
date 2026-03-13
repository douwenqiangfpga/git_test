onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider "top"
add wave -noupdate /tb_top/u_top/o_pwm1
add wave -noupdate /tb_top/u_top/o_pwm2
add wave -noupdate /tb_top/u_top/o_pwm3
add wave -noupdate /tb_top/u_top/o_pwm4

add wave -noupdate -divider "ctrl"
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/i_clk
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/i_rst_n
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/i_en
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/PHASE_STEP
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/MOD_INDEX

add wave -noupdate -divider "spwm_debug"
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/o_carrier_cnt
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/o_carrier_dir
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/o_lut_addr
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/o_ref_cmp

add wave -noupdate -divider "outputs"
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/o_pwm_raw
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/o_pwm_h
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/o_pwm_l

add wave -noupdate -divider "dut_internal"
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/update_tick
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/phase_acc
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/sine_u
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/sine_mod_u
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/ref_cmp

# ============================
# LUT / sine / scaling
# ============================
add wave -noupdate -divider "SINE_AND_SCALE"
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/sine_u
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/sin_bip0
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/prod1
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/prod_mid
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/sin_scaled
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/ref_s
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/ref_cmp_r
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/v0
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/v1
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/v2
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/v3

add wave -noupdate /tb_top/u_top/spwm_single_top_inst/carrier_d1
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/carrier_d2
add wave -noupdate /tb_top/u_top/spwm_single_top_inst/carrier_d3

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns}}
quietly wave cursor active 1
configure wave -namecolwidth 220
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -timelineunits ns
update

