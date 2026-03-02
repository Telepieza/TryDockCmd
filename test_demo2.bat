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

docker compose -f "%DIR_HOME%%COMPOSE_FILE%" down

:: =========================
:: LIMPIEZA FINAL DE TEMPORALES
:: =========================
echo Limpiando contenedores y volúmenes temporales nuevamente...
for /f "tokens=1" %%a in ('docker ps -a --filter "name=data-init" --format "{{.ID}}"') do docker rm -f %%a
for /f "tokens=1" %%v in ('docker volume ls --format "{{.Name}}" ^| findstr /i "trydockcmd_"') do (
    docker volume rm -f %%v
    echo Volumen temporal %%v eliminado
)


:: 1. Levantar la base de datos y el servidor en segundo plano
echo [1/4] Levantando infraestructura básica...
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" up -d postgres
:: Esperar unos segundos para que Postgres acepte conexiones
timeout /t 10 /nobreak

:: Crear el archivo de contraseña temporal en tu carpeta de config local

echo [2/4] Inicializando Esquema de Base de Datos (Tablas del Sistema)
echo admin > .\config\.passwd
:: Este comando crea la tabla ir_module y el usuario admin
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" run --rm ^
  -v "%CD%\config\.passwd:/tmp/.passwd" ^
  -e TRYTONPASSFILE=/tmp/.passwd ^
  server trytond-admin -d tryton --all --email "mariano@telepieza.com"

:: 2. Ejecutar el script de carga de datos y configuración
echo [3/4] Ejecutando auto_full_setup.py via Proteus...
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -f "%DIR_HOME%%COMPOSE_DATA%" run --rm -e PYTHONUNBUFFERED=1 data-init

:: 3. Levantar el servidor principal una vez configurado
echo [4/4] Iniciando servidor Tryton final...
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" up -d server cron

:: -------------------------
:: 1️⃣ Parar servicios activos
:: -------------------------
echo Parando servicios activos permanentes...
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" down -v
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -f "%DIR_HOME%%COMPOSE_DATA%" up data-init --abort-on-container-exit --exit-code-from data-init

:: -------------------------
:: 2️⃣ Limpiar contenedores temporales de import/export
:: -------------------------
echo Limpiando contenedores temporales...
for /f "tokens=1" %%a in ('docker ps -a --filter "name=data-init" --format "{{.ID}}"') do (
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
:: 6️⃣ Limpiar contenedores temporales tras importación
:: -------------------------

docker compose -f "%DIR_HOME%%COMPOSE_FILE%" down

:: =========================
:: LIMPIEZA FINAL DE TEMPORALES
:: =========================
echo Limpiando contenedores y volúmenes temporales nuevamente...
for /f "tokens=1" %%a in ('docker ps -a --filter "name=data-init" --format "{{.ID}}"') do docker rm -f %%a
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

:: LIMPIEZA DE VOLÚMENES ANÓNIMOS POST-PROTEUS ###
echo "Analizando volúmenes huérfanos en test_demo2..."

:: Opción A: Borrado de todos los volúmenes no usados (Dangling)
:: Es la más segura si ya eliminaste los contenedores temporales.
docker volume prune -f

:exit

echo ================================
echo PROCESO COMPLETO - Datos permanentes conservados
echo ================================
pause

