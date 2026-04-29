@echo off
:: =============================================================================== 
:: PROGRAM:   header.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.1.25
:: DATE:     29/04/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Check if Docker is running
:: =============================================================================== 
:: 1. Verificación de seguridad (Acceso desde tcd.bat)
call "%DIR_SCRIPT%startcontrol.bat" "%~1"
:: Analiza si la llamada es del tcd.bat
call "%DIR_SCRIPT%message.bat" "%APP%" "header %APP%"
:: 2. Verificación de Docker. Intentamos un comando ligero para ver si el motor de docker responde
:: 1. Comprobamos si existe docker en el ordenador
call "%DIR_SCRIPT%message.bat" "%CHECK%" "!LOG_INFO_SEARCP! docker"
where docker >nul 2>&1
if %errorlevel% neq 0 (
   call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!DKR_NOT_SERVER!"
   exit /b 1
)
docker info >nul 2>&1
if %errorlevel% neq 0 (
    :: Si falla, intentamos arrancar Docker Desktop, llamando al script startdocker.bat
    call "%DIR_SCRIPT%startdocker.bat" "%TRYTON%"
    if !errorlevel! neq 0 (
         exit /b 2
    )
    :: Esperamos 5 segundos extras para mantener el mensaje en pantalla.
    call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "timeout_start" "10" "1"
    :: Recomprobamos después del intento de arranque, si el motor responde
    docker info >nul 2>&1
    if !errorlevel! neq 0 (
        :: Código 2: Docker no está o no arrancó
        exit /b 2
    )
)
call "%DIR_SCRIPT%message.bat" "%CHECK%" "!LOG_INFO_ANSI!"
:: Analiza si el ordenador soporta colores, para colorear los textos de los input.
REM Genera secuencia ANSI temporal
for /F %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "ANSI_TEST=%ESC%[31mTEST%ESC%[0m"
REM Guarda resultado de prueba en fichero
(echo %ANSI_TEST%) > %LOGGER_TEMP%
REM Leer fichero
set "out="
for /F "usebackq tokens=* delims=" %%L in ("%LOGGER_TEMP%") do set "out=%%L"
if exist "%LOGGER_TEMP%" del /f /q "%LOGGER_TEMP%"
REM Si la secuencia aparece literal, no hay soporte
echo %out% | findstr /R "\[[0-9]*m" >nul
if %errorlevel% EQU 1 (
    set "ANSI_SUPPORTED=1"
    set "C_M_YELLOW=%ESC%[33m"  
    set "C_M_GREEN=%ESC%[32m" 
    set "C_M_RESET=%ESC%[0m"
)

call "%DIR_SCRIPT%message.bat" "%CHECK%" "reader: !LOG_INFO_PROCES!"
goto :exit

:exit
exit /b 0
