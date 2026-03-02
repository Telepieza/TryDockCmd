@echo off
:: ===============================================================================
:: PROGRAM:   install.demo.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    [Telepieza - Mariano Vallespín]
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      01/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Install trytond tryton demo
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: Analiza si la llamada es del tcd.bat
set "proyecto=%~1"
set "action=%~2"
set "DIR_HOME=%~dp0"
set "APPLICATION=TRYDOCKCMD DOCKER MANAGER"
:: Definir variables globales, añadir el idioma que se desee y en la variable LOCALE incluir el idioma.
set "es-ES=es-ES"
set "en-US=en-US"
:: Asignar por defecto el idioma si no encuentra el fichero .env
set "LOCALE=%es-ES%"
:: Constantes 
set "DIR_LOG=%DIR_HOME%log"
set "DIR_BACKUP=%DIR_HOME%backup"
set "DIR_LANG=%DIR_HOME%lang"
set "DIR_TMP=%DIR_HOME%tmp"
set "DIR_SQL=%DIR_HOME%sql"
set "DIR_SCRIPT=%DIR_HOME%scripts

set "log_action=!LOG-INFO!"
set /a "wait_timedem=10"
set "file_err=%DIR_TMP%\trytond_demo_err.txt"
set "file_log=%DIR_TMP%\trytond_demo_log.txt"
set "file_base=%DIR_TMP%\trytond_demo_base.txt"
set "file_table=%DIR_TMP%\trytond_demo_table.txt"
set "file_activ=%DIR_TMP%\trytond_demo_activ.txt"
set "file_xml=%DIR_TMP%\trytond_demo_xml.txt"
set "file_modules=%DIR_TMP%\trytond_demo_modules.txt"
set "file_csv_modultable=%DIR_TMP%\trytond_demo_modules_table.csv"
set "file_sql_exportable=%DIR_TMP%\trytond_demo_modules_table.sql"
set "PROGRAM=install_demo"

set "proyecto=tryton"
set "COMPOSE_FILE=compose.yml"
set "COMPOSE_DATA=compose_import.yml"

set "TRYTON=tryton"             
set "SERVER=server"
set "CRON=cron"
set "POSTGRES=postgres"
set "DB_NAME_DEMO=tryton"
set "TRYTON_VER="
set "PORT_TRYTON=8000"


@echo off
:: ===================================================================
:: PROGRAM:   test_demo.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    Telepieza - Mariano Vallespín
:: VERSION:   1.0.0
:: DATE:      01/03/2026
:: DESCRIPTION: Automatiza importación de datos Tryton con Docker
:: ===================================================================

setlocal enabledelayedexpansion
chcp 65001 >nul

:: -------------------------
:: CONFIGURACIÓN
:: -------------------------
set "DIR_HOME=%~dp0"
set "COMPOSE_FILE=compose.yml"
set "COMPOSE_DATA=compose_import.yml"

set "PORT_TRYTON=8000"
set "DB_NAME_DEMO=tryton"
set "DIR_LOG=%DIR_HOME%log"

:: Crear carpeta de logs si no existe
if not exist "%DIR_LOG%" mkdir "%DIR_LOG%"

:: -------------------------
:: FUNCIONES
:: -------------------------
:: Detener contenedor si puerto ocupado
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%PORT_TRYTON%"') do (
    echo Puerto %PORT_TRYTON% ocupado por PID %%a → verificando contenedor Docker
    for /f "tokens=1" %%b in ('docker ps --format "{{.ID}} {{.Ports}}" ^| findstr ":8000->"') do (
        echo Deteniendo contenedor %%b...
        docker stop %%b
        echo Contenedor %%b detenido
    )
)

:: -------------------------
:: 1️⃣ Parar servicios activos
:: -------------------------
echo Parando servicios activos permanentes...
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" down -v

:: -------------------------
:: 2️⃣ Limpiar contenedores temporales de import/export
:: -------------------------
echo Limpiando contenedores temporales...
for /f "tokens=1" %%a in ('docker ps -a --filter "name=data-init" --format "{{.ID}}"') do (
    docker rm -f %%a
    echo Contenedor temporal %%a eliminado
)
for /f "tokens=1" %%a in ('docker ps -a --filter "name=data-export" --format "{{.ID}}"') do (
    docker rm -f %%a
    echo Contenedor temporal %%a eliminado
)

:: =========================
:: LIMPIAR VOLUMENES TEMPORALES
:: =========================
for /f "tokens=1" %%v in ('docker volume ls --format "{{.Name}}" ^| findstr /i "trydockcmd_"') do (
    docker volume rm -f %%v
    echo Volumen temporal %%v eliminado
)

:: -------------------------
:: 4️⃣ Ejecutar importación de datos
:: -------------------------
echo Iniciando importación de datos...
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -f "%DIR_HOME%%COMPOSE_DATA%" run -T --rm data-init
:: docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -f "%DIR_HOME%%COMPOSE_DATA%" up data-init --abort-on-container-exit --exit-code-from data-init
:: docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -f "%DIR_HOME%%COMPOSE_DATA%" up -T data-init
if %errorlevel% neq 0 echo [ERROR] Hubo un problema al importar los datos CSV.

:: -------------------------
:: 5️⃣ (Opcional) Exportación de datos
:: -------------------------
:: echo Iniciando exportación de datos...
:: docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -f "%DIR_HOME%%COMPOSE_DATA%" run --rm data-export
:: if %errorlevel% neq 0 echo [ERROR] Hubo un problema al exportar los datos CSV.

:: -------------------------
:: 6️⃣ Limpiar contenedores temporales tras importación
:: -------------------------

docker compose -f "%DIR_HOME%%COMPOSE_FILE%" down -v

:: =========================
:: LIMPIEZA FINAL DE TEMPORALES
:: =========================
echo Limpiando contenedores y volúmenes temporales nuevamente...
for /f "tokens=1" %%a in ('docker ps -a --filter "name=data-init" --format "{{.ID}}"') do docker rm -f %%a
for /f "tokens=1" %%a in ('docker ps -a --filter "name=data-export" --format "{{.ID}}"') do docker rm -f %%a
for /f "tokens=1" %%v in ('docker volume ls --format "{{.Name}}" ^| findstr /i "trydockcmd_"') do (
    docker volume rm -f %%v
    echo Volumen temporal %%v eliminado
)

:: Esperar unos segundos para asegurar que arranca
timeout /t 5 >nul

: -------------------------
:: Levantar contenedor Tryton si no está corriendo
:: -------------------------
for /f "tokens=1,2" %%a in ('docker ps -a --filter "name=tryton-server-1" --format "{{.ID}} {{.Status}}"') do (
    set "SERVER_ID=%%a"
    set "SERVER_STATUS=%%b"
)

if defined SERVER_ID (
    echo Contenedor %SERVER_ID% encontrado con estado %SERVER_STATUS%
    echo %SERVER_STATUS% | findstr /i "Up" >nul
    if errorlevel 1 (
        echo Contenedor parado → iniciando %SERVER_ID%...
        docker start %SERVER_ID%
        echo Contenedor %SERVER_ID% levantado
    ) else (
        echo Contenedor ya estaba en ejecución
    )
) else (
    echo No se encontró el contenedor tryton-server-1
)


echo ================================
echo PROCESO COMPLETO - Datos permanentes conservados
echo ================================
pause

