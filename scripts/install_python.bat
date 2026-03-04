@echo off
:: ===============================================================================
:: PROGRAM:   install.python.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    [Telepieza - Mariano Vallespín]
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      01/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Install python 
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
set "proyecto=%~1"
set "ins_pyth_action=%~2"
set /a "wait_timepyt10=10"
set /a "wait_timepyt5=5"
set "log_action=!LOG-INFO!"
call "%DIR_SCRIPT%install_header.bat" "%proyecto%" "%ins_pyth_action%" "%PYTH%" "install_python"
if %errorlevel% EQU 2 (
   set "MESSAGE=!STAT_ERR_NOT_INSTALLED:PROYECTO=%proyecto%!"
   call :logger "!LOG-ERROR!" "!MESSAGE!"
   pause & goto :exit
)
if %errorlevel% EQU 4 (
   set "MESSAGE=!BCK_CONT_STOP:PROYECTO=%proyecto%!"
   call :logger "!LOG-ERROR!" "!MESSAGE!"
   pause & goto :exit
)

:: Si es de install.bat seguimos en el proceso de instalacion
if /i "!ins_pyth_action!"=="%INS%" set "log_action=%INS%"
:: Crear carpeta de logs y tmp si no existe
if not exist "%DIR_LOG%" mkdir "%DIR_LOG%"
if not exist "%DIR_TMP%" mkdir "%DIR_TMP%"
:: Detener contenedor si puerto ocupado (8000 - server)
call :docker_stop_port
call :logger "%INS%" "!INSTALL_MODU_HEAD41:PROYECTO=%%b!" "3"
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" down
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt5!" "1"
call :docker_clear

:: 1. Levantar la base de datos y el servidor en segundo plano
call :logger "%INS%" "[1/9] !INSTALL_MODU_HEAD42! %POSTGRES%" "3"
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" up -d "%POSTGRES%"
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt10!" "1"

:: Este comando crea la tabla ir_module y el usuario fichero .env
call :logger "%INS%" "[2/9] !INSTALL_MODU_HEAD43!" "3"
echo "!DB_USER!" > .\config\.passwd
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" run --rm ^
  -v "%CD%\config\.passwd:/tmp/.passwd" ^
  -e TRYTONPASSFILE=/tmp/.passwd ^
  "!SERVER!" trytond-admin -d "!DB_NAME!" --all --email "!EMAIL!"
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt10!" "1"

call :logger "%INS%" "[3/9] !INSTALL_MODU_HEAD44!" "3"
call :logger "%INS%" "[3.1] !BCK_FILE_ZIP! %DIR_TMP%\tmp\trytond_proteus.txt!" "5"
call :logger "%INS%" "[3.2] !INSTALL_MODU_HEAD45!" "5"
call :logger "%INS%" "[3.3] !INSTALL_MODU_HEAD46!" "5"
call :logger "%INS%" "[3.4] !INSTALL_MODU_HEAD47!" "5"
call :logger "%INS%" "[3.5] !INSTALL_MODU_HEAD48!" "5"
call :logger "%INS%" "[3.6] !INSTALL_MODU_HEAD49!" "5"
call :logger "%INS%" "[3.7] !INSTALL_MODU_HEAD50!" "5"
:: 2. Ejecutar el script de carga de datos y configuración
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -f "%DIR_HOME%%COMPOSE_DATA%" run --rm ^
-e PYTHONUNBUFFERED=1 ^
-e COMPANY_NAME="!CURRENT_COMPANY_NAME!" ^
-e COMPANY_CURRENCY="!CURRENT_COMPANY_CURRENCY!" ^
-e APP_LANGUAGE="!LOCALE!" ^
data-init
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt10!" "1"

:: 3. Levantar el servidor principal una vez configurado
call :logger "%INS%" "[4/9] !LOG_INSTALL_DOCKER!: %DIR_HOME%%COMPOSE_FILE% -p %proyecto% up -d"
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" up -d "%SERVER%" cron
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt10!" "1"

call :logger "%INS%" "[5/9] !LOG_WORK_STOP!"
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" down
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt5!" "1"

call :logger "%INS%" "[6/9] !INSTALL_MODU_HEAD51!"
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -f "%DIR_HOME%%COMPOSE_DATA%" up data-init --abort-on-container-exit --exit-code-from data-init
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt5!" "1"

call :docker_clear

call :logger "%INS%" "[7/9] !LOG_WORK_STOP!"
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" down
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt10!" "1"

call :logger "%INS%" "[8/9] !UP_STARTING:PROYECTO=%proyecto%!" "3"
call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%INS%"
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt10!" "1"

:: Eliminar y borrar contenedores y volumenes temporales.
call :logger "%INS%" "[9/9] !INSTALL_MODU_HEAD52!" "3"
docker volume prune -f
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt10!" "1"

call :logger "!LOG-SUCC!" "!INSTALL_MODU_END!" "3"
echo.
goto :exit

:docker_stop_port
:: Detener contenedor si puerto ocupado
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%SERVER_TARGET%"') do (
    set "MESSAGE=!INSTALL_PORT_6:CONEXION=%SERVER_TARGET%!"
    call :logger "%INS%" "!MESSAGE:PROYECTO=%%a!" "3"
     for /f "tokens=1" %%b in ('docker ps --format "{{.ID}} {{.Ports}}" ^| findstr ":%SERVER_TARGET%->"') do (
        call :logger "%INS%" "!INSTALL_MODU_HEAD36 %%b!" "5"
        docker stop %%b
        call :logger "%INS%" "!INSTALL_MODU_HEAD37:PROYECTO=%%b!" "5"
    )
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt5!" "1"
)
exit /b

:docker_clear
  :: =========================
  :: LIMPIEZA FINAL DE TEMPORALES
  :: =========================
  call :logger "%INS%" "!INSTALL_MODU_HEAD38:PROYECTO=%%b!" "3"
  for /f "tokens=1" %%a in ('docker ps -a --filter "name=data-init" --format "{{.ID}}"') do (
    docker rm -f %%a
    call :logger "%INS%" "!INSTALL_MODU_HEAD39 %%a!" "5"
  )
  for /f "tokens=1" %%v in ('docker volume ls --format "{{.Name}}" ^| findstr /i "trydockcmd_"') do (
    docker volume rm -f %%v
    call :logger "%INS%" "!INSTALL_MODU_HEAD40 %%v!" "5"
  )
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt5!" "1"
  exit /b

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:exit
  endlocal
  exit /b 0
