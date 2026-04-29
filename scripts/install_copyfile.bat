@echo off
:: ===============================================================================
:: PROGRAM:   install.copyfile.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.1.25
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

:: Check if the custom modules directory exists
call "%DIR_SCRIPT%message.bat" "%log_action%" "!INSTALL_MODU_HEAD71!" "3" 
set "TRYTON_BASE_MODULE=!TRYTON_BASE_MODULE_V7!"
if "!CURRENT_VERSION:~0,1!"=="8"  set "TRYTON_BASE_MODULE=!TRYTON_BASE_MODULE_V8!"
  :: Iterate through each subdirectory (module) in CUSTOM_MODULES_DIR
  for /d %%M in ("!DIR_MODULES!\*") do (
    set "MODULE_NAME=%%~nM"
    set "CONTAINER_MODULE_PATH=!TRYTON_BASE_MODULE!/!MODULE_NAME!"
    :: Check if the module exists in the container
    docker exec -u 0 !CURRENT_TRYTON! test -d "!CONTAINER_MODULE_PATH!" >nul 2>&1
    if !errorlevel! NEQ 0 (
        call "%DIR_SCRIPT%message.bat" "%log_action%" "!WORD_MODULE! !MODULE_NAME! !INSTALL_MODU_HEAD70! !TRYTON_BASE_MODULE!" "3"
        :: Copy the module from host to container
        docker cp "%%M" !CURRENT_TRYTON!:!CONTAINER_MODULE_PATH!
        if !errorlevel! EQU 0 (
            :: Ajuste de permisos y propietario para asegurar que Python pueda importar el módulo
            docker exec -u 0 !CURRENT_TRYTON! chown -R root:root "!CONTAINER_MODULE_PATH!" >nul 2>&1
            docker exec -u 0 !CURRENT_TRYTON! chmod -R 755 "!CONTAINER_MODULE_PATH!" >nul 2>&1           
            call "%DIR_SCRIPT%message.bat" "!log_action!" "!INSTALL_MODU_HEAD72! '!MODULE_NAME!' !INSTALL_MODU_HEAD74!" "3"
        ) else (
            call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_HEAD73! '!MODULE_NAME!' !INSTALL_MODU_HEAD74!" "3"
        )
    ) 
)

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
