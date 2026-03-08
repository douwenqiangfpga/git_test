onerror {resume}
quietly WaveActivateNextPane {} 0

# Testbench 关键信号
add wave -noupdate /tb_top/i_clk
add wave -noupdate /tb_top/i_rst_n

# DUT 顶层关键信号
add wave -noupdate /tb_top/u_top/pll_lock
add wave -noupdate /tb_top/u_top/clkout0
add wave -noupdate /tb_top/u_top/o_led
add wave -noupdate /tb_top/u_top/pwm_h
add wave -noupdate /tb_top/u_top/pwm_l

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns}}
quietly wave cursor active 1
configure wave -namecolwidth 220
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -timelineunits ns
update