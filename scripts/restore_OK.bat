@echo off
setlocal enabledelayedexpansion

:menu
cls
echo ========================================================
echo      GESTOR DE RESTAURACION - TRYTON DOCKER
echo ========================================================
echo  1. RESTAURAR TODO EL SERVIDOR (Archivo Total .sql)
echo  2. RESTAURAR SOLO ESTRUCTURA (En DB vacia)
echo  3. RESTAURAR SOLO DATOS (En DB con tablas existentes)
echo  4. RESTAURAR BASE INDIVIDUAL (Desde archivo .dump)
echo  5. Salir
echo ========================================================
set /p opt="Seleccione el tipo de restore (1-5): "

set CONTAINER=db
set USER=postgres
set BDIR=.\backup

if %opt%==1 goto restore_total
if %opt%==2 set MODE=SCHEMA&& goto validate_and_restore
if %opt%==3 set MODE=DATA&& goto validate_and_restore
if %opt%==4 set MODE=FULL_DB&& goto validate_and_restore
if %opt%==5 exit
goto menu

:validate_and_restore
echo.
set /p dbn="Nombre de la DB destino (Ej: tryton o tryton-demo): "

:: Comprobar si la DB existe para evitar errores de conexion
set EXISTS=0
for /f "tokens=*" %%i in ('docker compose exec -T %CONTAINER% psql -U %USER% -tAc "SELECT 1 FROM pg_database WHERE datname='%dbn%'"') do set EXISTS=%%i

if "!EXISTS!" NEQ "1" (
    echo [ERROR] La base de datos '%dbn%' no existe en el contenedor.
    echo Por favor, creela primero o verifique el nombre.
    pause
    goto menu
)

:: --- Lógica de Restauración ---

if "%MODE%"=="SCHEMA" (
    echo [INFO] Restaurando estructura en %dbn%...
    type %BDIR%\%dbn%_esquema.sql | docker compose exec -T %CONTAINER% psql -U %USER% -d %dbn%
)
if "%MODE%"=="DATA" (
    echo [INFO] Insertando datos en %dbn% (Omitiendo duplicados)...
    type %BDIR%\%dbn%_datos.sql | docker compose exec -T %CONTAINER% psql -U %USER% -d %dbn%
)
if "%MODE%"=="FULL_DB" (
    echo [INFO] Restaurando base completa desde binario...
    docker compose exec -T %CONTAINER% pg_restore -U %USER% -d %dbn% --clean --if-exists %BDIR%\%dbn%_completa.dump
)

echo [OK] Restauracion finalizada.
pause
goto menu

:restore_total
echo [ALERTA] Esto borrara/sobrescribira configuraciones globales.
set /p confirm="Confirmar restauracion total? (S/N): "
if /i "%confirm%" NEQ "S" goto menu

echo [INFO] Procesando restauracion total del cluster...
type %BDIR%\TOTAL_SERVER_BACKUP.sql | docker compose exec -T %CONTAINER% psql -U %USER%
echo [OK] Servidor restaurado completamente.
pause
goto menu