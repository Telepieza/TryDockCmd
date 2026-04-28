@echo off
:: ===============================================================================
:: PROGRAM:   install.header.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.1.1
:: DATE:      29/04/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Install header tryton version 7 y 8
:: ==============================================================================
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: Analiza si la llamada es del tcd.bat
set "proyecto=%~1"
set "ins_head_action=%~2"
set "type=%~3"
set "pgm=%~4"
set "log_error=0"

set "wfile_err=%DIR_TMP%\trytond_err"
set "wfile_log=%DIR_TMP%\trytond_log"
set "wfile_base=%DIR_TMP%\trytond_base"
set "wfile_table=%DIR_TMP%\trytond_table"
set "wfile_activ=%DIR_TMP%\trytond_activ"
set "wfile_xml=%DIR_TMP%\trytond_xml"
set "wfile_modules=%DIR_TMP%\trytond_modules"
set "wfile_csv_modultable=%DIR_TMP%\trytond_modules_table"
set "wfile_sql_exportable=%DIR_TMP%\trytond_modules_table"

call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call "%DIR_SCRIPT%message.bat" "%APP%" "install.header %ins_head_action% [%pgm%] %type%"
if /i "%ins_head_action%"=="%INS%" set "log_action=%INS%"

set "sufijo="
if /i "%type%"=="%DEMO%" set "sufijo=_demo"
if /i "%type%"=="%LANG%" if "%ins_head_action%"=="%APP%" set "sufijo=_lang"
if /i "%type%"=="%PYTH%" set "sufijo=_pyth"

set "file_err=%wfile_err%%sufijo%%EXT_TXT%"
set "file_log=%wfile_log%%sufijo%%EXT_TXT%"
set "file_base=%wfile_base%%sufijo%%EXT_TXT%"
set "file_table=%wfile_table%%sufijo%%EXT_TXT%"
set "file_activ=%wfile_activ%%sufijo%%EXT_TXT%"
set "file_xml=%wfile_xml%%sufijo%%EXT_TXT%"
set "file_modules=%wfile_modules%%sufijo%%EXT_TXT%"
set "file_csv_modultable=%wfile_csv_modultable%%sufijo%%EXT_CSV%"
set "file_sql_exportable=%wfile_sql_exportable%%sufijo%%EXT_SQL%"

if "%DB_URI%"=="" set "DB_URI=postgresql://%POSTGRES%:%DB_PASSWORD%@%DB_HOSTNAME%:%DB_PORT%/"

:: 1. Verificar existencia del proyecto tryton en docker
if /i "%ins_head_action%"=="%APP%" if /i "%CURRENT_TRYTON%"=="" if /i "%CURRENT_POSTGRES%"=="" (
  call "%DIR_SCRIPT%inspectdocker.bat" "%proyecto%" "%APP%"
  if %ERRORLEVEL% EQU 2 set "log_error=2" & goto :error
)
:: 2. Analiza estado de los contenedores y si están parados se arrancan
if /i "%ins_head_action%" NEQ "%INS%" (
  call "%DIR_SCRIPT%status.bat" %proyecto% "%CHECK%"
  if %ERRORLEVEL% NEQ 0 (
    call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%CHECK%"
    if %ERRORLEVEL% EQU 4 set "log_error=3" & goto :error
  )
)

:: 3.- Localizar la version de tryton y postgreSQL
if "!CURRENT_VERSION!"=="" call "%DIR_SCRIPT%checkversion.bat" "%proyecto%"
if %ERRORLEVEL% EQU 4 set "log_error=4" & goto :error
exit /b 

:error
  set "MESSAGE="
  if "%log_error%" EQU "2" set "MESSAGE=!STAT_ERR_NOT_INSTALLED:PROYECTO=%proyecto%!"
  if "%log_error%" EQU "3" set "MESSAGE=!STAT_ERR_NOT_INSTALLED:PROYECTO=%proyecto%!"
  if "%log_error%" EQU "4" set "MESSAGE=!BCK_CONT_STOP:PROYECTO=%proyecto%!"
  if /i "!MESSAGE!" NEQ "" call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "[%log_error%] !MESSAGE!"
  pause 
  exit /b 2
