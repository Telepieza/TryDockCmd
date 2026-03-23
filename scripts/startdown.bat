@echo off
:: ==============================================================================
:: PROGRAM:   startdown.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      23/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Shut Down Containers - Parar los contenedores (STOP)
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
set "proyecto=%~1"
set "down_action=%~2"
set "type_stop=%~3"
set "log_action=!LOG-INFO!"
set /a "wait_service=2"
:: Analiza si la llamada es del tcd.bat
call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call :logger "%APP%" "startdown %down_action%"
:: 1. Verificar existencia mediante el script de inspección de instalación de trypton en Docker
if /i "%down_action%"=="%APP%" if /i "%CURRENT_TRYTON%"=="" if /i "%CURRENT_POSTGRES%"=="" (
  call "%DIR_SCRIPT%inspectdocker.bat" "%proyecto%" "%APP%"
  if %errorlevel% equ 2 (
    set "MESSAGE=!DOWN_NOT_FOUND:PROYECTO=%proyecto%!"
    call :logger "!LOG-ERROR!" "!MESSAGE!"
    goto :exit
  )
)

if /i "%type_stop%"=="" set "type_stop=STOP"

if /i "%down_action%"=="%INS%" (
   set "log_action=%INS%"
   goto :continue
)
if /i "%down_action%"=="%CHECK%" (
  set "log_action=%CHECK%"
  goto :continue
)

if /i "%down_action%"=="%APP%" (
  call "%DIR_SCRIPT%status.bat" "%proyecto%" "%SEE%"
)

:: Solicita confirmación YES por parte del usuario para continuar. 
set /p "confirm=%BS%        !C_M_GREEN!!DOWN_CONFIRM!!C_M_RESET!"
if /i "%confirm%" NEQ "YES" (
::  call :logger "!LOG-WARN!" "!DOWN_ERR_OPT!"
    goto :exit
)

:continue
:: 2. Comprobar si hay contenedores activos para parar todos ellos, usando el filtro del proyecto (tryton)
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps --status running -q | findstr "^" >nul 2>&1
if %errorlevel% equ 0 (
    set "MESSAGE=!DOWN_STOPPING:PROYECTO=%proyecto%!"
    call :logger "!log_action!" "!MESSAGE!"
    :: Usamos 'stop' en lugar de 'down' para mantener los contenedores creados
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_service!" "1"
    if /i "%type_stop%"=="DOWN" (
      docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" down
    ) else (
      docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" stop
    )
    if !errorlevel! equ 0 (
        set "MESSAGE=!DOWN_SUCCESS:PROYECTO=%proyecto%!"
        call :logger "!LOG-SUCC!" "!MESSAGE! %type_stop%"
    ) else (
        set "MESSAGE=!DOWN_WARN:PROYECTO=%proyecto%!"
        call :logger "!LOG-WARN!" "!MESSAGE! %type_stop%"
    )
) else (
    set "MESSAGE=!DOWN_ALREADY:PROYECTO=%proyecto%!"
    call :logger "!LOG-WARN!" "!MESSAGE! %type_stop%"
)
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_service!" "1"
if /i "%down_action%"=="%APP%" (
  echo.
  call "%DIR_SCRIPT%status.bat" "%proyecto%" "%SEE%"
  pause
)

goto :exit

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2"
  exit /b

:exit
  endlocal
  exit /b 0