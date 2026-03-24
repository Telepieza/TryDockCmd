@echo off
:: =============================================================================== 
:: PROGRAM:   install.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      23/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Deploy ERP TRYTON (First time) - Instalar Tryton/Arrancar (INSTALL)   
:: =============================================================================== 
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: Analiza si la llamada es del tcd.bat
set "proyecto=%~1"
set /a "wait_timeins=10"
set /a "wait_timeins20=20"
set "active_client=YES"
call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call "%DIR_SCRIPT%message.bat" "%APP%" "install %APP%"
: Verifica si los contenedores no existen
call "%DIR_SCRIPT%inspectdocker.bat" "%proyecto%" "%INS%"
if %errorlevel% EQU 2 (
  echo.
  set "MESSAGE=!INSP_FOUND:PROYECTO=%proyecto%!"
  call "%DIR_SCRIPT%message.bat" "!MENU!" "!MESSAGE!" "3"
  echo.
  set "confirm="
  :: Solicita confirmación por parte del usuario para cancelar instalacion
  set /p "confirm=%BS%        !C_M_GREEN!!INSTALL_EXITS!!C_M_RESET!"
  if /i "!confirm!" NEQ "YES" goto :cancel
  goto :continue
)
set "MESSAGE=!INSTALL_DESC_1:PROYECTO=%proyecto%!"
call "%DIR_SCRIPT%message.bat" "%INS%" "!MESSAGE!"
call "%DIR_SCRIPT%message.bat" "%INS%" "!INSTALL_DESC_2!"
echo.
call "%DIR_SCRIPT%message.bat" "%INS%" "!LOG_INSTALL_DOCKER!: %DIR_HOME%%COMPOSE_FILE% -p %proyecto% up -d"
:: Usamos -p %proyecto% para que el nombre del proyecto sea el que pasamos por parametro
:: 'up -d' descarga, crea y arranca en segundo plano en un solo paso
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" up -d
if %errorlevel% NEQ 0 (
  set "MESSAGE=!LOG_INSTALL_ERR:PROYECTO=%proyecto%!"
  call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!MESSAGE!"
  goto :error
)
set "MESSAGE=!LOG_INSTALL_SUCC:PROYECTO=%proyecto%!"
call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!MESSAGE!"
:: Al llamar con el call nos esperamos 10 s, tiempo suficiente para dar tiempo de ejecucion a cada uno de ellos.
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeins!" "1"

:continue
  call "%DIR_SCRIPT%status.bat" "%proyecto%" "%INS%"
  :: Contenedores parados o la DDBB no acepta conexiones.
  if %errorlevel% NEQ 0 (
    :: Arranca contenedores y conexion DDBB
    call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%INS%"
    :: Una vez solucionado se vuelve a llamar a status.bat
    if %errorlevel% NEQ 0 (
      call "%DIR_SCRIPT%message.bat" "%INS%" "!STAT_START!"
      call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeins!" "1"
      call "%DIR_SCRIPT%status.bat" "%proyecto%" "%INS%"
    )
  )
  :: Instalar modulos en tryton
  call "%DIR_SCRIPT%message.bat" "%INS%" "!MENU-OPTION_8!"
  call "%DIR_SCRIPT%install_tryton.bat" "%proyecto%" "%INS%"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeins20!" "1" 
  :: Instalar demo con database-(version).dump
  call "%DIR_SCRIPT%message.bat" "%INS%" "!MENU-OPTION_9:VERSION=%CURRENT_VERSION%!"
  call "%DIR_SCRIPT%install_demo.bat" "%proyecto%" "%INS%"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeins20!" "1"

  :: Realizamos llamada al cliente para visualizar la página web
  set "MESSAGE=!STAT_HTTP:PROYECTO=%proyecto%!"
  call "%DIR_SCRIPT%message.bat" "%INS%" "!MESSAGE!"
  call "%DIR_SCRIPT%client.bat" "%proyecto%" "%INS%"
  if %errorlevel% NEQ 0 call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!STAT_NOT_HTTP!"  
  
  if "%ACTIVE_COPY%" NEQ "0" (
    docker exec -u 0 !CURRENT_TRYTON! rm -f /tmp/auto_full_setup.py
    docker exec -u 0 !CURRENT_TRYTON! rm -f /tmp/trytond_setup.conf
    set "ACTIVE_COPY=0"
  )
  :: Buscar errores en los log de Docker
  call "%DIR_SCRIPT%errors.bat" "%proyecto%" "%INS%"
  echo.
  call "%DIR_SCRIPT%message.bat" "%LOG-SUCC%" "install !LOG_INFO_PROCES!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeins!" "1"

  goto :exit

:cancel
 endlocal
 exit /b 2

:error
 endlocal
 exit /b 3

:exit
  endlocal
  exit /b 0
