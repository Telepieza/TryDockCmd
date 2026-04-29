@echo off
:: ===============================================================================
:: PROGRAM:   readcompose.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.1.25
:: DATE:     29/04/2026
:: LICENSE:   MIT License
:: DESCRIPTION: read compose.yml
:: ==============================================================================
:: Cambia la consola a UTF-8
chcp 65001 >nul
set /a "attempts=0"
set /a "max_attempts=5"
set /a "wait_timerea=2"
set "LOAD_FILE=0"
:: control de llamada, solo se permite desde tcd.bat
call "%DIR_SCRIPT%startcontrol.bat" "%~1"
call "%DIR_SCRIPT%message.bat" "%APP%" "readcompose"
:: controla si existe read-compose.ps1
call "%DIR_SCRIPT%message.bat" "%CHECK%" "[1/4] !LOG_INFO_SEARCH! %DIR_HOME%%READ_FILEPS1%"
if not exist "%DIR_HOME%%READ_FILEPS1%" set "LOAD_FILE=1"
:: controla si existe compose.yml
call "%DIR_SCRIPT%message.bat" "%CHECK%" "[2/4] !LOG_INFO_SEARCH! %DIR_HOME%%COMPOSE_FILE%"
if not exist "%DIR_HOME%%COMPOSE_FILE%" if "%LOAD_FILE%"=="0" set "LOAD_FILE=2"
:: Falta controlar pwsh es powerShell 7+ Intruccion : pwsh -NoProfile -ExecutionPolicy Bypass -File %DIR_HOME%%READ_FILEPS1%
:: controla si existe el programa powershell.exe
if "%LOAD_FILE%"=="0" (
  call "%DIR_SCRIPT%message.bat" "%CHECK%" "[3/4] !LOG_INFO_SEARCP! powershell.exe"
  where powershell.exe >nul 2>&1
  if %errorlevel% NEQ 0 set "LOAD_FILE=3"
)
:: existen errores no es posible realizar la lectura con poweshell
if "%LOAD_FILE%" NEQ "0" goto :continue
:: Primera lectura para ver si existen errores
call "%DIR_SCRIPT%message.bat" "%CHECK%" "[4/4] !LOG_INFO_DATA! powershell.exe %DIR_HOME%%READ_FILEPS1%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%DIR_HOME%%READ_FILEPS1%" >nul 2>&1
if %errorlevel% NEQ 0 (
  set "LOAD_FILE=4"
  goto :continue
)
:: Procedemos leer los datos con posible bucle
:loop_powershell
  for /f "usebackq delims=" %%A in (`
      powershell.exe -NoProfile -ExecutionPolicy Bypass -File %DIR_HOME%%READ_FILEPS1% 
  `) do (
  set "%%A"
  )
  :: localizamos los datos, si las variables de las imagenes tienen datos nos vamos.
  if /i "%SERVER_IMAGE%" NEQ "" if /i "%POSTGRES_IMAGE%" NEQ "" goto :continue
  :: Para ordenadores lentos realizamos varios bucles de espera, segun variable configuracion.
  <nul set /p=.
    if %attempts% GEQ %max_attempts% (
      set "LOAD_FILE=4"
      goto :continue
    )
  set /a attempts+=1
  call "%DIR_SCRIPT%message.bat" "%CHECK%" "!LOG_INFO_LOOP! [%attempts%/%max_attempts%]"
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "timeout_start" "!wait_timerea! " "1"
  goto :loop_powershell

:continue
  call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_COMPOSE%"
  if /i "%SERVER_IMAGE%" neq "" call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_SERVER% %SERVER_IMAGE%"
  if /i "%SERVER_IMAGE_NAME%" neq "" call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_SERVER_NAME% %SERVER_IMAGE_NAME%"
  if /i "%SERVER_IMAGE_VERSION%" neq "" call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_SERVER_VERSION% %SERVER_IMAGE_VERSION%"
  if /i "%SERVER_PORT_TARGET%" neq "" call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_SERVER_TARGET% %SERVER_PORT_TARGET%"
  if /i "%SERVER_PORT_PUBLISHED%" neq "" call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_SERVER_PUBLISHED% %SERVER_PORT_PUBLISHED%"
  if /i "%POSTGRES_IMAGE%" neq "" call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_POSTGRES% %POSTGRES_IMAGE%"
  if /i "%POSTGRES_IMAGE_NAME%" neq "" call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_POSTGRES_NAME% %POSTGRES_IMAGE_NAME%"
  if /i "%POSTGRES_IMAGE_VERSION%" neq "" call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_POSTGRES_VERSION% %POSTGRES_IMAGE_VERSION%"

  :: Si las variables no tienen datos, se pasan las de omision.
  if /i "%SERVER_IMAGE%"=="" ( 
    set "SERVER_IMAGE=%TRYTON_TRYTON%:%TRYTON_VERSION%"
    call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_SERVER% %TRYTON% %SERVER_IMAGE%"
  )
  if /i "%SERVER_IMAGE_NAME%"=="" (
    set "SERVER_IMAGE_NAME=%TRYTON%/%TRYTON%"
    call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_SERVER_NAME% %TRYTON% %SERVER_IMAGE_NAME%" 
  )
  if /i "%SERVER_IMAGE_VERSION%"=="" (
    set "SERVER_IMAGE_VERSION=%TRYTON_VERSION%"
    call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_SERVER_VERSION% %TRYTON% %SERVER_IMAGE_VERSION%"
  )
  if /i "%SERVER_PORT_TARGET%"=="" (
    set "SERVER_PORT_TARGET=%SERVER_TARGET%"
    call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_SERVER_TARGET% %TRYTON% %SERVER_PORT_TARGET%"
  )
  if /i "%SERVER_PORT_PUBLISHED%"=="" (
    set "SERVER_PORT_PUBLISHED=%SERVER_PUBLISHED%"
    call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_SERVER_PUBLISHED% %TRYTON% %SERVER_PORT_PUBLISHED%"
  )
  if /i "%CRON_IMAGE%"=="" set "CRON_IMAGE=%SERVER_IMAGE%"
  if /i "%CRON_IMAGE_NAME%"=="" set "CRON_IMAGE_NAME=%SERVER_IMAGE_NAME%"
  if /i "%CRON_IMAGE_VERSION%"=="" set "CRON_IMAGE_VERSION=%SERVER_IMAGE_VERSION%"

  if /i "%POSTGRES_IMAGE%"=="" (
    set "POSTGRES_IMAGE=%POSTGRES%:%POSTGRES_VERSION%"
    call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_POSTGRES% %TRYTON% %POSTGRES_IMAGE%"
  )
  if /i "%POSTGRES_IMAGE_NAME%"=="" (
    set "POSTGRES_IMAGE_NAME=%POSTGRES%"
    call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_POSTGRES_NAME% %TRYTON% %POSTGRES_IMAGE_NAME%"
  )
  if /i "%POSTGRES_IMAGE_VERSION%"=="" (
    set "POSTGRES_IMAGE_VERSION=%POSTGRES_VERSION%"
    call "%DIR_SCRIPT%message.bat" "%CHECK%" "%LOG_INFO_POSTGRES_VERSION% %TRYTON% %POSTGRES_IMAGE_VERSION%"
  )
  call "%DIR_SCRIPT%message.bat" "%CHECK%" "readcompose: !LOG_INFO_PROCES!"
  exit /b
