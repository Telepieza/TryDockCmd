@echo off
:: ===============================================================================
:: PROGRAM:   errors.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini Code Assist
:: VERSION:   1.1.25
:: DATE:      29/04/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Smart Audit (Last 24h) - Errores graves (últimas 24h) (ERRORS)
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
set "proyecto=%~1"
set "err_action=%~2"
set "log_action=!LOG-INFO!"
set /a "wait_timerr=5"
:: Analiza si la llamada es del tcd.bat
call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call "%DIR_SCRIPT%message.bat" "%APP%" "errors %err_action%"
:: Verifica si el contenedor existe
if /i "%err_action%"=="%APP%" if /i "%CURRENT_TRYTON%"=="" if /i "%CURRENT_POSTGRES%"=="" (
  call "%DIR_SCRIPT%inspectdocker.bat" "%proyecto%" "%APP%"
  if %errorlevel% equ 2 (
    set "MESSAGE=!LOG_ERR_NOTFOUND:PROYECTO=%proyecto%!"
    call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!MESSAGE!"
    goto :exit
  )
)
if /i "%err_action%"=="%INS%" set "log_action=%INS%"
set "msg_cont=%proyecto% - !WORD_SERVICE!: %service%" 
set "MESSAGE=!ERR_SEARCHING:PROYECTO=%proyecto%!"

:: Borramos el fichero temporal
if exist "%LOGGER_TEMP%" del /f /q "%LOGGER_TEMP%"
:: Se crea sin registros
type nul > "%LOGGER_TEMP%"
:: Logs error Postgres
call :logs_service "%POSTGRES%"
:: Logs error server
call :logs_service "%SERVER%"
:: Logs error cron
call :logs_service "%CRON%"
echo.
:: Comprobamos que exista. En teoria siempre tiene que existir
if not exist "%LOGGER_TEMP%" (
    call "%DIR_SCRIPT%message.bat" "%log_action%" "!ERR_TEMPORY!"
    goto :exit
)
echo.
:: Analizamos si el fichero temporal tiene errores.
set size=0
for /f "tokens=*" %%i in ("%LOGGER_TEMP%") do set size=%%~zi
if %size% GTR 0 (
    call "%DIR_SCRIPT%message.bat" "!LOG-ALERT!" "!ERR_DETECTED!"
    :: Volcar errores al log principal y mostrar en pantalla
    for /f "usebackq delims=" %%L in ("%LOGGER_TEMP%") do (
      set "LINE=%%L"
      call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!LINE!"
    )
    echo.
    set "MESSAGE=!ERR_REPORT:LOGGERFILE=%LOGGER%!"
    call "%DIR_SCRIPT%message.bat" "%log_action%" "!MESSAGE!"
    set "MESSAGE=!ERR_REPORT:LOGGERFILE=%LOGGER_TEMP%!"
    call "%DIR_SCRIPT%message.bat" "%log_action%" "!MESSAGE!"
    echo.
) else (
    call "%DIR_SCRIPT%message.bat" "%log_action%" "!ERR_CLEAN!"
)
goto :exit

:logs_service
  set "service=%~1"
  set "msg_cont="
  if /i "%service%" equ "%POSTGRES%" set "msg_cont=%CURRENT_POSTGRES% - !WORD_SERVICE!: %service%" 
  if /i "%service%" equ "%CRON%" set "msg_cont=%CURRENT_CRON% - !WORD_SERVICE!: %service%"
  if /i "%service%" equ "%SERVER%" set "msg_cont=%CURRENT_TRYTON% - !WORD_SERVICE!: %service%" 
  set "MESSAGE=!ERR_SEARCHING:PROYECTO=%msg_cont%!"
  call "%DIR_SCRIPT%message.bat" "%log_action%" "!MESSAGE!"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" logs --since=24h "%service%" 2>nul | findstr /I "%ERROR_PATTERNS%" >> "%LOGGER_TEMP%"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timerr!" "1"
  exit /b

:exit
  endlocal
  exit /b 0