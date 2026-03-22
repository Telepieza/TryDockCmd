@echo off
:: =========================================================================================
:: PROGRAM:   checkdocker.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      23/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Check image and containers - Comprobar imagenes y contenedores con docker inspect
:: ==============================================================================================
:: Cambia la consola a UTF-8
chcp 65001 >nul
set /a "wait_service=2"
:: 1. Verificación de seguridad
call "%DIR_SCRIPT%startcontrol.bat" "%~1"
call :logger "%APP%" "checkdocker %APP%"
:: 2. Definición de variables locales con sus nombres de contenedor, %~1 suele ser "tryton"
set "MESSAGE=!INSP_SEARCHING:PROYECTO=%~1!"
call :logger "%CHECK%" "!MESSAGE!"
set "ERR_DOCKER=0"
set "LOG_FILE=0"
set "cons_server=%TRYTON%-%SERVER%-1"
set "cons_db=%TRYTON_POSTGRES%-1"
set "cons_cron=%TRYTON%-%CRON%-1"
call :logger "%CHECK%" "!LOG_INFO_DOCKIM! %SERVER_IMAGE%"
if /i "%SERVER_IMAGE%" NEQ "" call :read_image "%SERVER_IMAGE%"
:: No existe imagen tryton
if "%ERR_DOCKER%"=="1" goto :continue
call :logger "%CHECK%" "!LOG_INFO_DOCKIM! %POSTGRES_IMAGE%"
if /i "%POSTGRES_IMAGE%" NEQ "" call :read_image "%POSTGRES_IMAGE%"
:: No existe imagen postgres
if "%ERR_DOCKER%"=="1" goto :continue

if /i "!CURRENT_POSTGRES!" EQU "" if /i "!CURRENT_TRYTON!" EQU "" (
   for /f "tokens=*" %%i in ('docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%TRYTON%" ps --format "{{.Names}}"') do (
      set "NAME_CONT=%%i"
      echo !NAME_CONT! | findstr "%SERVER%" >nul
      if !errorlevel! EQU 0 set "CURRENT_TRYTON=%%i"
      echo !NAME_CONT! | findstr "%CRON%" >nul
      if !errorlevel! EQU 0 set "CURRENT_CRON=%%i"
      echo !NAME_CONT! | findstr "%POSTGRES%" >nul
      if !errorlevel! EQU 0 set "CURRENT_POSTGRES=%%i"
   )
)

if /i "!CURRENT_POSTGRES!"=="" (
  set "LOG_FILE=0"
  call :read_container "!cons_db!"
  if "%LOG_FILE%"=="0" set "CURRENT_POSTGRES=!cons_db!"
  if /i "!CURRENT_POSTGRES!"=="" (
    call :read_container "%POSTGRES%"
    if "%LOG_FILE%"=="0" set "CURRENT_POSTGRES=%POSTGRES%"
  )
  if "%LOG_FILE%" GTR 0 set "ERR_DOCKER=%LOG_FILE%"
)

if /i "!CURRENT_TRYTON!"=="" (
  set "LOG_FILE=0"
  call :logger "%CHECK%" "!LOG_INFO_DOCKCO! !cons_server!"
  call :read_container "!cons_server!"
  if "%LOG_FILE%"=="0" set "CURRENT_TRYTON=!cons_server!"
  if /i "!CURRENT_TRYTON!"=="" (
    call :logger "%CHECK%" "!LOG_INFO_DOCKCO! %TRYTON%"
    call :read_container "%TRYTON%"
    if "%LOG_FILE%"=="0" set "CURRENT_TRYTON=%TRYTON%"
  )
  if "%LOG_FILE%" GTR 0 set "ERR_DOCKER=%LOG_FILE%"
)

if /i "!CURRENT_CRON!"=="" (
  set "LOG_FILE=0"
  call :logger "%CHECK%" "!LOG_INFO_DOCKCO! !cons_cron!"
  call :read_container "!cons_cron!"
  if "%LOG_FILE%"=="0" set "CURRENT_CRON=!cons_cron!"
  if /i "!CURRENT_CRON!"=="" (
    call :logger "%CHECK%" "!LOG_INFO_DOCKCO! %TRYTON%-%CRON%"
    call :read_container "%TRYTON%-%CRON%"
    if "%LOG_FILE%"=="0" set "CURRENT_CRON=%TRYTON%-%CRON%"
  )
  if  "%LOG_FILE%" GTR 0 set "ERR_DOCKER=%LOG_FILE%"
)

:continue
  if /i "!CURRENT_TRYTON!"=="" (
    call :logger "%CHECK%" "!INSP_NOT_CONTAINER! !cons_server!"
  ) else (
    call :logger "%CHECK%" "!INSP_CONTAINER! !CURRENT_TRYTON!"
  )
  if /i "!CURRENT_POSTGRES!"=="" (
      call :logger "%CHECK%" "!INSP_NOT_CONTAINER! !cons_db!"
  ) else (
      call :logger "%CHECK%" "!INSP_CONTAINER! !CURRENT_POSTGRES!"
  )
 
  if /i "!CURRENT_CRON!"=="" (
      call :logger "%CHECK%" "!INSP_NOT_CONTAINER! !cons_cron!"
  ) else (
      call :logger "%CHECK%" "!INSP_CONTAINER! !CURRENT_CRON!"
  )

  if /i "!CURRENT_POSTGRES!"=="" set "CURRENT_POSTGRES=!cons_db!"
  if /i "!CURRENT_TRYTON!"=="" set "CURRENT_TRYTON=!cons_server!"  
  if /i "!CURRENT_CRON!"=="" set "CURRENT_CRON=!cons_cron!"
  if /i "!CURRENT_VERSION!"=="" set "CURRENT_VERSION=%TRYTON-VERSION%"
  if /i "!CURRENT_VER_MENU!"=="" set "CURRENT_VER_MENU=%TRYTON-VERSION%"
  if /i "!CURRENT_PG_VERSION!"=="" set "CURRENT_PG_VERSION=%POSTGRES_VERSION%"
  set "LOG_FILE=0"
  if "%ERR_DOCKER%" NEQ "0" (
    exit /b 2
  )
  call :logger "%CHECK%" "checkdocker: !LOG_INFO_PROCES!"
  goto :exit

:read_image
  docker inspect "%~1" >nul 2>&1
  if %errorlevel% equ 0 set "MESSAGE=!INSP_IMAGE:NAME=%~1!"
  if %errorlevel% neq 0 (
    set "ERR_DOCKER=1"
    set "MESSAGE=!INSP_NOT_IMAGE:NAME=%~1!"
  )
  call :logger "%CHECK%" "!MESSAGE!"
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "timeout_start" "!wait_service!" "1"
  exit /b

:read_container
  set "MESSAGE=!INSP_CONTAINER:NAME=%~1!"
  docker inspect "%~1" >nul 2>&1
  if %errorlevel% neq 0 (
    set /a LOG_FILE+=1
    set "MESSAGE=!INSP_NOT_CONTAINER:NAME=%~1!"
  )
  call :logger "%CHECK%" "!MESSAGE!"
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "timeout_start" "!wait_service!" "1"
  exit /b

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2"
  exit /b

:exit
  exit /b 0
 