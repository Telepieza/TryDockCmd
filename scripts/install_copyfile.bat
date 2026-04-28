@echo off
:: ===============================================================================
:: PROGRAM:   install.copyfile.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.1.0
:: DATE:      28/04/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Install copy file container tryton version 7 y 8
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: Analiza si la llamada es del tcd.bat
set "proyecto=%~1"
set "ins_file_action=%~2"
set "log_error=0"
set "log_action=%APP%"

call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call "%DIR_SCRIPT%message.bat" "%APP%" "install_copyfile %ins_file_action%"
if /i "%ins_file_action%"=="%INS%" set "log_action=%INS%"

set "lorigenpy=!DIR_PYTHON!auto_full_setup.py"
set "sdestinopy=!CURRENT_TRYTON!:/tmp/auto_full_setup.py"
set "lorigencof=!DIR_CONFIG!trytond.conf"
set "sdestinocof=!CURRENT_TRYTON!:/tmp/trytond_setup.conf"

if not exist "%lorigenpy%"  set "log_error=5" 
if /i "%log_error%" EQU "0" if not exist "!lorigencof!" set "log_error=6"

if /i "%log_error%" EQU "0" (
  call "%DIR_SCRIPT%message.bat" "!CHECK!" "!lorigencof! !sdestinocof!"
  docker cp "!lorigencof!" "!sdestinocof!" > nul
  if %ERRORLEVEL% NEQ 0 set "log_error=7"
)

if /i "%log_error%" EQU "0" (
  call "%DIR_SCRIPT%message.bat" "!CHECK!" "!lorigenpy! !sdestinopy!"
  docker cp "!lorigenpy!" "!sdestinopy!" > nul
  if %ERRORLEVEL% NEQ 0 set "log_error=8" 
)

if "%log_error%" EQU "0" (
  set "ACTIVE_COPY=1"
  exit /b
)

set "MESSAGE="
if "%log_error%" EQU "5" set "MESSAGE=!LOG_ERR_FILE:ARCHIVO=%DIR_PYTHON%auto_full_setup.py!"
if "%log_error%" EQU "6" set "MESSAGE=!LOG_ERR_FILE:ARCHIVO=%DIR_CONFIG%trytond.conf!"
if "%log_error%" EQU "7" set "MESSAGE=!LOG_ERR_FILE:ARCHIVO=%DIR_CONFIG%trytond.conf!"
if "%log_error%" EQU "8" set "MESSAGE=!LOG_ERR_FILE:ARCHIVO=%DIR_PYTHON%auto_full_setup.py!"
if /i "!MESSAGE!" NEQ "" call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "[%log_error%] !MESSAGE!"
pause 
exit /b 2
