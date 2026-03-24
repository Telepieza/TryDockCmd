@echo off
::===============================================================================
:: PROGRAM:   logger.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      23/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: View Service Activity - Visualizar la actividad (LOGS)
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: APP o INS (INSTALL)
set "proyecto=%~1"
set "logger_action=%~2"
set "lines="
set "log_action=!LOG-INFO!"
set "logger_tmp=%DIR_LOG%\%TRYTON%_logger.log"

:: Analiza si la llamada es del tcd.bat
call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%" "%APP%"
call "%DIR_SCRIPT%message.bat" "%APP%" "logger %logger_action%"
:: Verifica si el contenedor existe

if /i "%logger_action%"=="%INS%" (
  set "log_action=%INS%"
  set "lines=100"
  goto :continue
) 

if /i "%logger_action%"=="%SQL%" (
  set "log_action=%SQL%"
  set "lines=500"
  goto :continue
) 

if /i "%logger_action%"=="%APP%" if /i "%CURRENT_TRYTON%"=="" if /i "%CURRENT_POSTGRES%"=="" (
  call "%DIR_SCRIPT%inspectdocker.bat" "%proyecto%" "%APP%"
  if %errorlevel% equ 2 (
    set "MESSAGE=!LOG_ERR_NOTFOUND:PROYECTO=%proyecto%!"
    call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!MESSAGE!"
    goto :exit
  )
)
:: Lógica principal del Logger
call "%DIR_SCRIPT%message.bat" "!log_action!" "!LOG_LINES_INFO!"

:other_logger
  echo.
  set "lines="
  set "confirm="
  set /p "lines=%BS%        !C_M_YELLOW!!LOG_PROMPT!!C_M_RESET! "
  if "%lines%"=="" set "lines=50"
  echo.
  set "MESSAGE=!LOG_VIEWING:LINES=%lines%!"
  call "%DIR_SCRIPT%message.bat" "%log_action%" "!MESSAGE!"
  call :extract_logs
  echo.
  set /p "confirm=%BS%        !C_M_GREEN!!LOG_CONFIRM!!C_M_RESET! "
  if /i "%confirm%"=="YES" goto :exit
  goto :other_logger

:continue
  :: Ejecución de docker-compose para el servicio específico
  set "MESSAGE=!LOG_VIEWING:PROYECTO=%proyecto%!"
  set "MESSAGE=!MESSAGE:LINES=%lines%!"
  call "%DIR_SCRIPT%message.bat" "%log_action%" "!MESSAGE!"
  :: Servicio postgres BBDD
  call :extract_errors "%POSTGRES%"
  if /i "%logger_action%" NEQ "%SQL%" ( 
    :: Servicio Tryton Server
    call :extract_errors "%SERVER%"
    :: Servicio Tryton Cron
    call :extract_errors "%CRON%"
  )
  goto :exit

:extract_errors
  set "service=%~1"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps "%service%" --status running -q | findstr "^" >nul 2>&1
  if %errorlevel% equ 0 (
    set "MESSAGE=!LOG_CONTAINER:NAME=%service%!"
    call "%DIR_SCRIPT%message.bat" "%log_action%" "!MESSAGE!"
    docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" logs --tail="%lines%" "%service%"
  )
  exit /b

:extract_logs
  set "MESSAGE=!LOG_PROYECT:PROYECTO=%proyecto%!"
  call "%DIR_SCRIPT%message.bat" "%log_action%" "!MESSAGE!"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" logs --tail="%lines%" > "%logger_tmp%"
  :: type "%logger_tmp%"
  for /F "usebackq tokens=* delims=" %%L in ("%logger_tmp%") do (
    set "line=%%L"
      set "line=!line:>= !" ^
    & set "line=!line:<= !" ^
    & set "line=!line:|= !" ^
    & set "line=!line:&= !" ^
    & set "line=!line:^= !" ^
    & set "line=!line:%%= !" ^
    & set "line=!line:"= !"
    if defined line (
        echo !line!
        call "%DIR_SCRIPT%message.bat" "%CHECK%" "!WORD_MESSAGE! !line!"
    )
  )
  exit /b

:exit
  endlocal
  exit /b 0
