@echo off
:: =====================================================================================
:: PROGRAM:   checkversion.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    [Telepieza - Mariano Vallespín]
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      01/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Check version (STATUS)
:: =====================================================================================
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: APP o INS (INSTALL)
set "proyecto=%~1"
:: Analiza si la llamada es del tcd.bat
call :logger "%APP%" "checkversion %APP%"
call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
if "%CURRENT_VERSION%" EQU "" set "CURRENT_VERSION=%TRYTON_VERSION%"
if "%CURRENT_VER_MENU%" EQU "" set "CURRENT_VER_MENU=%TRYTON_VERSION%"
if /i "%CURRENT_VERSION%" NEQ "%TRYTON_VERSION%" goto :pg_version
if /i "%CURRENT_VERSION%" NEQ "%LATEST%" goto :pg_version
call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%CHECK%"
if %errorlevel% NEQ 0 exit /b 4
:: 1. Detectar la versión de tryton, localizando el valor en el contenedor server a tres puntos ejemplo 7.8.3

if /i "%CURRENT_TRYTON%" NEQ "" set "cont_server=%CURRENT_TRYTON%"
if /i "%CURRENT_TRYTON%" EQU "" set "cont_tryton=%TRYTON%"

call :logger "%CHECK%" "!LOG_INFO_DOCKIN! [%cont_server%]"
docker inspect "%cont_server%" >nul 2>&1
if %errorlevel% NEQ 0 docker inspect "%cont_tryton%" >nul 2>&1
if %errorlevel% NEQ 0 goto :tryton_version

call :logger "%CHECK%" "!LOG_INFO_SERVER_VERSEAR! - (trytond.__version__.split('.')[:3])"
for /f "tokens=*" %%V in ('docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%SERVER%" python3 -c "import trytond; print('.'.join(trytond.__version__.split('.')[:3]))"') do (
    set "CURRENT_VER_MENU=%%V"  
)
:: Se eliminan desde el ultimo punto hasta el final, quedando en 7.8
if /i "!CURRENT_VER_MENU!" NEQ "%LATEST%" (
    for /f "tokens=1,2 delims=." %%A in ("!CURRENT_VER_MENU!") do set "CURRENT_VERSION=%%A.%%B"
)

:tryton_version
  call :logger "%CHECK%" "!LOG_INFO_VERSION!: [!CURRENT_VERSION!]"
  call :logger "%CHECK%" "!LOG_INFO_VERSION!: [!CURRENT_VER_MENU!]"

:pg_version
  if "%CURRENT_PG_VERSION%" EQU "" set "CURRENT_PG_VERSION=%POSTGRES_VERSION%"
  if /i "%CURRENT_PG_VERSION%" NEQ "%POSTGRES_VERSION%" goto :exit
  if /i "%CURRENT_PG_VERSION%" NEQ "%LATEST%" goto :exit
  
  if "!DB_NAME!"=="" set "DB_NAME=%TRYTON%"
  if "!TRYTON_DB_DEMO!"=="" set "TRYTON_DB_DEMO=%DB_NAME_DEMO%"
  if /i "%DB_NAME_DEMO%" NEQ "%TRYTON_DB_DEMO%" set "DB_NAME_DEMO=%TRYTON_DB_DEMO%"
  
  call :logger "%CHECK%" "!LOG_INFO_DOCKIN! [%POSTGRES%] - [SELECT 1 FROM pg_catalog.pg_database WHERE datname='!DB_NAME!]"
  set "CURRENT_PGALL_VERSION="
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U "%POSTGRES%" -d "!DB_NAME!" -tA -c "SELECT 1 FROM pg_catalog.pg_database WHERE datname='!DB_NAME!';" >nul 2>&1
  if %ERRORLEVEL% NEQ 0 goto :pg_not_datname
  call :logger "%CHECK%" "!LOG_INFO_SERVER_VERSEPO! - [SELECT version()]"
  for /f "tokens=*" %%V in ('
    docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U "%POSTGRES%" -d "!DB_NAME!" -tA -c "SELECT version();"
  ') do set "CURRENT_PGALL_VERSION=%%V"
  if  "!CURRENT_PGALL_VERSION!" NEQ "" (
    set "MESSAGE=!LOG_INFO_PG_VERSION:PROYECTO=%DB_NAME%!"
    call :logger "%CHECK%" "!MESSAGE!: [!CURRENT_PGALL_VERSION!]"
    for /f "tokens=1,2 delims= " %%A in ("!CURRENT_PGALL_VERSION!") do (
      set "CURRENT_PG_VERSION=%%A %%B"
    )
  )

  :pg_not_datname
    if /i "!CURRENT_PG_VERSION!" EQU "" set "CURRENT_PG_VERSION=%POSTGRES_VERSION%"
    if /i "!CURRENT_PGALL_VERSION!" EQU "" set "CURRENT_PGALL_VERSION=%POSTGRES_VERSION%"
    set "MESSAGE=!LOG_INFO_PG_VERSION:PROYECTO=%DB_NAME%!"
    call :logger "%CHECK%" "!MESSAGE!: [!CURRENT_PG_VERSION!]"
    call :logger "%CHECK%" "checkversion: !LOG_INFO_PROCES!"
    goto :exit

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2"
  exit /b

:exit
  :: Devolvemos el control al tcd
  exit /b 0
