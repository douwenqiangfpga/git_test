@echo off

call "%~dp0env.bat"

set SCRIPT_DIR=%~dp0
set ROOT_DIR=%~dp0..

set BUILD_DIR=%ROOT_DIR%\build\pds

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

cd /d "%BUILD_DIR%"
pds_shell -file "%SCRIPT_DIR%pds_run.tcl"

pause