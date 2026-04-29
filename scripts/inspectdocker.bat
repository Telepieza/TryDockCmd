@echo off
:: =========================================================================================
:: PROGRAM:   inspectdocker.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.1.11
:: DATE:      29/04/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Check containers - Comprobar contenedores con docker inspect y docker ps -a
:: =========================================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: 1. Verificación de seguridad
set "proyecto=%~1"
set "idr_action=%~2"
set /a "wait_service=2"
call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
set "PROGRAM=inspectdocker"
call "%DIR_SCRIPT%message.bat" "%APP%" "%PROGRAM% %idr_action%"

:: 2. Definición de variables locales con sus nombres de contenedor, %~1 suele ser "tryton"
set "conw_server=%TRYTON%-%SERVER%-1"
set "conw_db=%TRYTON_POSTGRES%-1"
set "conw_batch=%TRYTON%-%CRON%-1"
set "img_server=%TRYTON_TRYTON%:%TRYTON_VERSION%"
set "img_postgres=%POSTGRES%:%POSTGRES_VERSION%"
set "log_action=%APP%"

set "conz_tryton="
set "conz_postgres="
set "conz_cron="
set "exist_container=0"
set "exist_tryton=0"
set "exist_cron=0"
set "exist_postgres=0"
set "exist_image=0"
set "exist_imgtryton=0"
set "exist_imgpostgres=0"

if /i "%CURRENT_VERSION%" EQU "" set "CURRENT_VERSION=%TRYTON_VERSION%"
if /i "%CURRENT_VER_MENU%" EQU "" set "CURRENT_VER_MENU=%TRYTON_VERSION%"
if /i "%CURRENT_PG_VERSION%" EQU "" set "CURRENT_PG_VERSION=%POSTGRES_VERSION%"
if /i "%CURRENT_TRYTON%" NEQ "" set "conw_server=%CURRENT_TRYTON%"
if /i "%CURRENT_TRYTON%" EQU "" set "conz_tryton=%TRYTON%"
if /i "%CURRENT_POSTGRES%" NEQ "" set "conw_db=%CURRENT_POSTGRES%"
if /i "%CURRENT_POSTGRES%" EQU "" set "conz_postgres=%POSTGRES%"
if /i "%CURRENT_CRON%" NEQ "" set "conw_batch=%CURRENT_CRON%"
if /i "%CURRENT_CRON%" EQU "" set "conz_cron=%TRYTON%-%CRON%"
if /i "%SERVER_IMAGE%" NEQ "" set "img_server=%SERVER_IMAGE%"
if /i "%POSTGRES_IMAGE%" NEQ "" set "img_postgres=%POSTGRES_IMAGE%"

if /i "%idr_action%"=="%INS%" set "log_action=%INS%"
 
set "MESSAGE=!INSP_SEARCHING:PROYECTO=%proyecto%!" 
call "%DIR_SCRIPT%message.bat" "%CHECK%" "!MESSAGE!" "3"
echo.

:: Chequea el controlador postgres en función de la varaible idr_action siendo APP o INS (INSTALL)
:: Las opciones 1 a 6 tienen que existir los controladores la llamada al programa se realiza con APP
:: La opción 0 no tiene que existir los controladores, la llamada al programa se realiza con INS (INSTALAR)
:: La opcion 7

:: 3. MÉTODO 1: Búsqueda por nombres específicos (Fallback).
:: Chequear la existencias de las imágenes tryton:tryton y postgres
call :check_image "%img_server%"
set "exist_imgtryton=%exist_image%"
call :check_image "%img_postgres%"
set "exist_imgpostgres=%exist_image%"

:: Chequear los contenedores tryton, postgress y cron de las imágenes existentess
:: Contenedor tryton (Depende de la imagen de tryton), es el primero en ser chequeado
call :check_container "%conw_server%" "%conz_tryton%"
set "exist_tryton=%exist_container%"
:: Contenedor postgres (Depende de la imagen de postgres), es el segundo en ser chequeado
call :check_container "%conw_db%" "%conz_postgres%"
set "exist_postgres=%exist_container%"
:: Contenedor cron de tryton (Depende de la imagen de tryton), es el tercero en ser chequeado
call :check_container "%conw_batch%" "%conz_cron%"
set "exist_cron=%exist_container%"
:: Las variables que empiezan por EXIST_ puedes tener un valor 0=Es OK, 1=Es Error

if "%exist_imgtryton%"=="1" goto :error 
if "%exist_imgpostgres%"=="1" goto :error 
if "%exist_tryton%"=="1" goto :error 
if "%exist_postgres%"=="1" goto :error 
if "%exist_cron%"=="1" goto :error 

:: 3.1 Auditoría de ADN (Pip packages) - Solo si el contenedor está corriendo
docker ps -q --filter "name=%conw_server%" | findstr "^" >nul
if %errorlevel% equ 0 (
    call "%DIR_SCRIPT%message.bat" "%CHECK%" "--- AUDITORÍA DE PAQUETES PIP (V8) ---" "3"
    docker exec %conw_server% pip list | findstr "trytond_account trytond_country"
    echo.
)

:: 4. MÉTODO 1: Búsqueda por Label (El más profesional para Docker Compose). Docker Compose etiqueta los contenedores con el nombre del proyecto.

docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps -a -q | findstr "^" >nul 2>&1
:: docker ps -a -q --filter "label=com.docker.compose.project=%proyecto%" | findstr "^" >nul

if %errorlevel% equ 0  if /i "%idr_action%"=="%APP%" (
  set "MESSAGE=!INSP_FOUND:PROYECTO=%proyecto%!"
  call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!MESSAGE!" 
  goto :exit
)

if %errorlevel% neq 0  if /i "%idr_action%"=="%INS%" (
  set "MESSAGE=!INSP_NOT_FOUND:PROYECTO=%proyecto%!"
  call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!MESSAGE!"  
)
goto :exit

:check_image
  set "img_check=%~1"
  set "exit_image=0"
  docker inspect "%img_check%" >nul 2>&1

  if /i "%idr_action%"=="%APP%" ( 
    if %errorlevel% neq 0 (
       set "exist_image=1"
       set "MESSAGE=!INSP_NOT_IMAGE:NAME=%img_check%!"
       call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!MESSAGE!"  
    ) else (
      set "MESSAGE=!INSP_IMAGE:NAME=%img_check%!"
      call "%DIR_SCRIPT%message.bat" "%log_action%" "!MESSAGE!"  
    )
  )

  if /i "%idr_action%"=="%INS%" (
    if %errorlevel% equ 0 (
        set "exist_image=1"
        set "MESSAGE=!INSP_IMAGE:NAME=%img_check%!"
        call "%DIR_SCRIPT%message.bat" "!LOG-WARN!" "!MESSAGE!"  
    ) else (
        set "MESSAGE=!INSP_NOT_IMAGE:NAME=%img_check%!"
        call "%DIR_SCRIPT%message.bat" "%log_action%" "!MESSAGE!"  
    )
  )
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_service! " "1"
  exit /b

:check_container
  set "cont_check1=%~1"
  set "cont_check2=%~2"
  set "exist_container=0"
  set "cont_try=%cont_check1%"
  docker inspect "%cont_check1%" >nul 2>&1
  if %errorlevel% neq 0 if /i "%cont_check2%" NEQ ""  (
    set "cont_try=%cont_check2% - %cont_check1%" 
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_service! " "1"
    docker inspect "%cont_check2%" >nul 2>&1
  )

  if /i "%idr_action%"=="%APP%" ( 
    if %errorlevel% neq 0 (
       set "exist_container=1"
       set "MESSAGE=!INSP_NOT_CONTAINER! %cont_try%"
       call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!MESSAGE!"  
    ) else (
      set "MESSAGE=!INSP_CONTAINER! %cont_try%"
      call "%DIR_SCRIPT%message.bat" "%log_action%" "!MESSAGE!"  
    )
  )
  
  if /i "%idr_action%"=="%INS%" (
    if %errorlevel% equ 0 (
        set "exist_container=1"
        set "MESSAGE=!INSP_CONTAINER! %cont_try%"
        call "%DIR_SCRIPT%message.bat" "!LOG-WARN!" "!MESSAGE!" 
    ) else (
        set "MESSAGE=!INSP_NOT_CONTAINER! %cont_try%"
        call "%DIR_SCRIPT%message.bat" "%log_action%" "!MESSAGE!"  
    )
  )
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_service! " "1"
  exit /b

:error
  endlocal
  exit /b 2

:exit
  endlocal
  exit /b 0
