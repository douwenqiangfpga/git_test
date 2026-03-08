@echo off

call "%~dp0env.bat"

cd /d %~dp0
call "%MODELSIM_BIN%/vsim" -gui -do run_sim.tcl -l sim.log

if exist transcript del /q transcript
if exist vsim.wlf del /q vsim.wlf
if exist *.vstf del /q *.vstf
if exist wlft* del /q wlft*

pause