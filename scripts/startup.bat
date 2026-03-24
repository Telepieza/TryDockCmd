@echo off
:: ==============================================================================
:: PROGRAM:   startup.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      23/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Power On containers - Arrancar los contenedores (START) 
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
set "proyecto=%~1"
set "up_action=%~2"
set /a "attempts=0"
set /a "max_attempts=10"
set /a "wait_timeup=8"
set /a "wait_service=3"
set /a "LOAD_FILE=0"
set "db_error=0"
set "exist_postgres=0"
set "log_action=!LOG-INFO!"
set "see_msg="

:: Analiza si la llamada es del tcd.bat
call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call :logger "%APP%" "startup %up_action%"

:: 1. Verificar existencia mediante el script de inspección de instalación de trypton en Docker
if /i "%up_action%"=="%APP%" if /i "%CURRENT_TRYTON%"=="" if /i "%CURRENT_POSTGRES%"=="" (
  call "%DIR_SCRIPT%inspectdocker.bat" "%proyecto%" "%APP%"
  if %errorlevel% equ 2 (
    set "MESSAGE=!UP_NOT_FOUND:PROYECTO=%proyecto%!"
    call :logger "!LOG-ERROR!" "!MESSAGE!"
    goto :exit
  )
)

::Proceso de instalacion 
if /i "%up_action%"=="%INS%" (
  set "log_action=%INS%"
  set "see_msg=N"
  goto :continue
)

:: Chequea los contenedores para analizar si están parados.
if /i "%up_action%"=="%CHECK%" (
  set "log_action=%CHECK%"
  goto :continue
)

:: Chequea los contenedores para analizar si están parados.
if /i "%up_action%"=="%SQL%" (
  set "log_action=%CHECK%"
  goto :continue
)

if /i "%up_action%"=="%APP%" (
  call "%DIR_SCRIPT%status.bat" "%proyecto%" "%SEE%"
)

:: Solicita confirmación YES por parte del usuario para continuar. 
set /p "confirm=%BS%        !C_M_GREEN!!UP_CONFIRM!!C_M_RESET! "
if /i "!confirm!" NEQ "YES" (
::  call :logger "!LOG-WARN!" "!UP_ERR_OPT!"
    goto :exit
)

:continue
  call :up_services "%POSTGRES%"
  if /i "%LOAD_FILE%" GTR 0 set "exist_postgres=1"
  if /i "%up_action%" NEQ "%SQL%" (
    call :up_services "%SERVER%"
    call :up_services "%CRON%"
  )
  :: Comprobando si la DB postgres acepta conexiones
  if /i "%exist_postgres%"=="0" if /i "%CURRENT_POSTGRES%" NEQ "" if /i "%up_action%" NEQ "%CHECK%" call :connect_postgres "%POSTGRES%"
  :: Problemas al activar los contenedores
  if "%LOAD_FILE%" GTR 0 (
    set "msg_cont=%proyecto% - !WORD_NUMBER! : %LOAD_FILE% !WORD_SERVICE!" 
    set "MESSAGE=!UP_WARN_FAIL:PROYECTO=%msg_cont%!"
    if /i "%up_action%"=="%INS%" call :logger "%log_action%" "!LOG-WARN! !MESSAGE!"
    if /i "%up_action%" NEQ "%INS%" call :logger "!LOG-WARN!" "!MESSAGE!"
    goto :status_stop
  )

  if "%db_error%"=="1" goto :error_connection

  if /i "%up_action%"=="%APP%" (
    echo.
    call "%DIR_SCRIPT%status.bat" "%proyecto%" "%SEE%"
    pause
  )

  goto :exit

:up_services
  set "service=%~1"
  set "msg_cont="
  if /i "%service%" equ "%POSTGRES%" set "msg_cont=%CURRENT_POSTGRES% - !WORD_SERVICE!: %service%" 
  if /i "%service%" equ "%CRON%" set "msg_cont=%CURRENT_CRON% - !WORD_SERVICE!: %service%"
  if /i "%service%" equ "%SERVER%" set "msg_cont=%CURRENT_TRYTON% - !WORD_SERVICE!: %service%" 
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps "%service%" --status running -q | findstr "^" >nul 2>&1
  if %errorlevel% equ 0 (
    set "MESSAGE=!UP_ACTIVE:PROYECTO=%msg_cont%!"
    call :logger "%log_action%" "!MESSAGE!"
    goto :exit_services
  )
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_service!" "1" "N"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%TRYTON%" start "%service%" >nul 2>&1
  if !errorlevel! neq 0 (
     if "%up_action%" NEQ "%INS%" (
       set "MESSAGE=!UP_WARN_FAIL:PROYECTO=%msg_cont%!"
       if /i "%up_action%"=="%INS%" call :logger "%log_action%" "!LOG-WARN! !MESSAGE!"
       if /i "%up_action%" NEQ "%INS%" call :logger "!LOG-WARN!" "!MESSAGE!"
     )
     set /a LOAD_FILE+=1
    goto :exit_services
  )  

  set "MESSAGE=!UP_SUCCESS:PROYECTO=%msg_cont%!"
  if /i "%up_action%"=="%INS%" call :logger "%log_action%" "!LOG-SUCC! !MESSAGE!"
  if /i "%up_action%" NEQ "%INS%" call :logger "!LOG-SUCC!" "!MESSAGE!"

:exit_services
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_service!" "1" "!see_msg!"
  exit /b

:connect_postgres
  set "service=%~1"
  set "msg_cont=%CURRENT_POSTGRES% - !WORD_SERVICE!: %service%" 
  set "MESSAGE=!UP_TESTING_DB:PROYECTO=%msg_cont%!"
  call :logger "%log_action%" "!MESSAGE!"
:loop_postgres
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_service!" "1" "N"
  docker exec "%CURRENT_POSTGRES%" pg_isready -U "%DB_USER%" >nul 2>&1
  if %errorlevel% equ 0 (
    if "%up_action%" NEQ "%INS%" (
      set "MESSAGE=!UP_CONNECT_DB:PROYECTO=%msg_cont%!"
      if /i "%up_action%"=="%INS%" call :logger "%log_action%" "!LOG-SUCC! !MESSAGE!"
      if /i "%up_action%" NEQ "%INS%" call :logger "!LOG-SUCC!" "!MESSAGE!"
    )
    goto :end_postgres
  )
  if %attempts% GEQ %max_attempts% (
    if /i "%up_action%"=="%INS%" call :logger "%log_action%" "!LOG-ERROR! !UP_WAIT_DB2!"
    if /i "%up_action%" NEQ "%INS%" call :logger "!LOG-ERROR!" "!UP_WAIT_DB2!"
    set "db_error=1"
    goto :end_postgres
  )
  <nul set /p=.
  set /a attempts+=1
  set "MESSAGE=!UP_WAIT_DB1:COUNT=%attempts%!"
  if /i "%up_action%"=="%INS%" call :logger %log_action% "!LOG-WARN! !MESSAGE!"
  if /i "%up_action%" NEQ "%INS%" call :logger "!LOG-WARN!" "!MESSAGE!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeup!" "1"
  goto :loop_postgres

:end_postgres
  exit /b
  
:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:container_stop
  endlocal
  exit /b 4

:status_stop
  endlocal
  exit /b 2

:error_connection
  endlocal
  exit /b 3

:exit
  endlocal
  exit /b 0
