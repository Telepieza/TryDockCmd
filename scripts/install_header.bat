@echo off
:: ===============================================================================
:: PROGRAM:   install.header.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    [Telepieza - Mariano Vallespín]
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      01/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Install header tryton
:: ==============================================================================
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: Analiza si la llamada es del tcd.bat
set "proyecto=%~1"
set "ins_head_action=%~2"
set "type=%~3"
set "pgm=%~4"

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
call :logger "%APP%" "install.header %ins_head_action% [%pgm%] %type%"
if /i "%ins_head_action%"=="%INS%" set "log_action=%INS%"

set "sufijo="
if /i "%type%"=="%DEMO%" set "sufijo=_demo"
if /i "%type%"=="%LANG%" if "%ins_head_action%"=="%APP%" set "sufijo=_lang"

set "file_err=%wfile_err%%sufijo%%EXT_TXT%"
set "file_log=%wfile_log%%sufijo%%EXT_TXT%"
set "file_base=%wfile_base%%sufijo%%EXT_TXT%"
set "file_table=%wfile_table%%sufijo%%EXT_TXT%"
set "file_activ=%wfile_activ%%sufijo%%EXT_TXT%"
set "file_xml=%wfile_xml%%sufijo%%EXT_TXT%"
set "file_modules=%wfile_modules%%sufijo%%EXT_TXT%"
set "file_csv_modultable=%wfile_csv_modultable%%sufijo%%EXT_CSV%"
set "file_sql_exportable=%wfile_sql_exportable%%sufijo%%EXT_SQL%"

set "DB_URI=postgresql://%POSTGRES%:%DB_PASSWORD%@%DB_HOSTNAME%:%DB_PORT%/"

:: 1. Verificar existencia del proyecto tryton en docker
if /i "%ins_head_action%"=="%APP%" if /i "%CURRENT_TRYTON%"=="" if /i "%CURRENT_POSTGRES%"=="" (
  call "%DIR_SCRIPT%inspectdocker.bat" "%proyecto%" "%APP%"
  if %errorlevel% equ 2 exit /b 2
)
:: 2. Analiza estado de los contenedores y si están parados se arrancan
if /i "%ins_head_action%" NEQ "%INS%" (
  call "%DIR_SCRIPT%status.bat" %proyecto% "%CHECK%"
  if %errorlevel% NEQ 0 (
    :: Nos aseguramos que los contenedores están activos
    call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%CHECK%"
    if %errorlevel% equ 4 exit /b 4
  )
)
:: 3.- Localizar la version de tryton y postgreSQL
if "!CURRENT_VERSION!"=="" call "%DIR_SCRIPT%checkversion.bat" "%proyecto%"
if %errorlevel% equ 4 exit /b 4
:: 4.- Localizar los modulos de tryton (Base y lenguajes)
call :logger "%CHECK%" "!INSTALL_MODU_35!"
call "%DIR_SCRIPT%base_modules.bat" "%proyecto%"
exit /b 0
:: 5.- Llamar al programa de mensajes si hay problemas 
:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b
