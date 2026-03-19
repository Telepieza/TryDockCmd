@echo off
:: =====================================================================================
:: PROGRAM:   status.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      23/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Check containers and images - Comprobar imágenes y contenedores (STATUS)
:: =====================================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: APP o INS (INSTALL)
set "proyecto=%~1"
set "est_action=%~2"
set "log_action=!LOG-INFO!"
set "db_error=0"
set "LOAD_FILE=0"
:: Analiza si la llamada es del tcd.bat
call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call :logger "%APP%" "status %est_action%"
:: 1. Verificar existencia del proyecto tryton en docker
if /i "%est_action%"=="%APP%" if /i "%CURRENT_TRYTON%"=="" if /i "%CURRENT_POSTGRES%"=="" (
  call "%DIR_SCRIPT%inspectdocker.bat" "%proyecto%" "%APP%"
  if %errorlevel% equ 2 (
     set "MESSAGE=!STAT_ERR_NOT_INSTALLED:PROYECTO=%proyecto%!"
     call :logger "!LOG-ERROR!" "!MESSAGE!"
     goto :exit
  )
)
:: Instalacion
if /i "%est_action%"=="%INS%" set "log_action=%INS%"
:: Chequear los contenedores
if /i "%est_action%"=="%CHECK%" set "log_action=%CHECK%"
if /i "%est_action%"=="%SEE%" set "log_action=%CHECK%"
if /i "%est_action%"=="%SQL%" set "log_action=%CHECK%"
:: Visualizar los contenedores
if /i "%est_action%" NEQ "%SEE%" (
  set "MESSAGE=!STAT_ACTIVE:PROYECTO=%proyecto%!"
  call :logger "%log_action%" "!MESSAGE!"
  call :logger "%log_action%" "!STAT_DETAILS_ACT!"
)
:: 2. Comprobar contenedores activos, se utiliza el nombre del proyecto tryton
:: Formateamos la tabla con columnas claras: Nombre, Imagen, Servico, Estado y Puertos

if /i "%est_action%" EQU "%SQL%" (
   echo.
   docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps "%POSTGRES%" -a --format "table {{.Name}}\t{{.Image}}\t{{.Service}}\t{{.Status}}\t{{.State}}\t{{.Ports}}"
) else if /i "%est_action%" NEQ "%CHECK%" (
   echo.
   docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps -a --format "table {{.Name}}\t{{.Image}}\t{{.Service}}\t{{.Status}}\t{{.State}}\t{{.Ports}}"
) 
:: Indicar que solo deseamos visualizar los Contenedores, servicios y state
if /i "%est_action%" == "%SEE%" echo. & goto :exit
:: Comprobar si la base de datos admite conexiones.
if /i "%CURRENT_POSTGRES%"=="" set "CURRENT_POSTGRES=%TRYTON_POSTGRES%-1"
if /i "%CURRENT_TRYTON%"=="" set "CURRENT_TRYTON=%TRYTON%-%SERVER%-1"
if /i "%CURRENT_CRON%"=="" set "CURRENT_CRON=%TRYTON%-%CRON%-1"

if /i "%est_action%" NEQ "%CHECK%" echo.
call :status_controler "%POSTGRES%"
call :connect_postgres "%POSTGRES%"
if /i "%est_action%" NEQ "%SQL%" (
  call :status_controler "%SERVER%"
  call :status_controler "%CRON%"
  if /i "%est_action%" NEQ "%CHECK%" echo.
)

if /i "%est_action%"=="%CHECK%" if "%db_error%"=="1" set "db_error=0"
if "%LOAD_FILE%"=="0" if "%db_error%"=="0" goto :exit
if "%LOAD_FILE%"=="1" goto :status_stop
if "%db_error%"=="1" goto :error_connection
goto :exit 

:status_controler
  set "service=%~1"
  set "msg_cont="
  if /i "%service%" equ "%POSTGRES%" set "msg_cont=%CURRENT_POSTGRES% - !WORD_SERVICE!: %service%" 
  if /i "%service%" equ "%CRON%" set "msg_cont=%CURRENT_CRON% - !WORD_SERVICE!: %service%"
  if /i "%service%" equ "%SERVER%" set "msg_cont=%CURRENT_TRYTON% - !WORD_SERVICE!: %service%" 
  set "MESSAGE=!STAT_ACTIVE_2:PROYECTO=%msg_cont%!"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps "%service%" | findstr /I "Up" >nul
  if %errorlevel% neq 0 (
    set "MESSAGE=!STAT_STOPPED_2:PROYECTO=%msg_cont%!"
    set "LOAD_FILE=1"
  )
  call :logger "%log_action%" "!MESSAGE!"
  exit /b

:connect_postgres
    set "service=%~1"
    set "msg_cont=%CURRENT_POSTGRES% - !WORD_SERVICE!: %service%" 
    set "MESSAGE=!UP_CONNECT_DB:PROYECTO=%msg_cont%!"
    docker exec "%CURRENT_POSTGRES%" pg_isready -U "%DB_USER%" >nul 2>&1
    if %errorlevel% neq 0 (
      set "db_error=1"
      set "MESSAGE=!UP_WAIT_DB3:PROYECTO=%msg_cont%!"
    )
    call :logger "%log_action%" "!MESSAGE!"
    exit /b

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2"
  exit /b

:status_stop
  endlocal
  exit /b 2

:error_connection
  endlocal
  exit /b 3

:exit
  endlocal
  exit /b 0