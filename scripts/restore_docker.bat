@echo off
REM ===============================================================================
REM PROGRAM:   restore_docker.bat
REM PROJECT:   Tryton Docker Manager
REM AUTHOR: Telepieza
REM COLLABORATOR: Gemini (Google AI)
REM VERSION:   1.0.0
REM DATE:      23/03/2026
REM LICENSE:   MIT License
REM DESCRIPTION: Database Hot-Import (Importr imágenes y Base de datos (RESTORE)
REM ==============================================================================
setlocal enabledelayedexpansion
chcp 65001 >nul
set "proyecto=%~1"
set "BACKUP_PATH=%~2"
set "DO_IMAGES=%~3"
set "DUMPALL_FILE=%~4"
set /a "attempts=0"
set /a "max_attempts=10"
set /a "wait_timeres=10"

call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call :logger "%APP%" "restore_docker"

call :logger !LOG-INFO! "!RES_STEP1!"
if "%DO_IMAGES%"=="1" (
  call "%DIR_SCRIPT%startdown.bat" "%proyecto%" "%CHECK%" "DOWN"
  if "!errorlevel!" NEQ 0 (
    set "MESSAGE=!RES_ERR_CMD! docker compose down"
    goto :error
  )
  call :logger !LOG-INFO! "!RES_STEP2!"
  docker load < "%BACKUP_PATH%\img_postgres.tar"
  if "!errorlevel!" NEQ 0 (
    set "MESSAGE=!RES_ERR_CMD! docker load img_postgres.tar"
    goto :error
  )
  docker load < "%BACKUP_PATH%\img_tryton.tar"
  if "!errorlevel!" NEQ 0 (
    set "MESSAGE=!RES_ERR_CMD! docker load img_tryton.tar"
    goto :error
  )
  call :logger !LOG-INFO! "!RES_STEP3!"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" up -d
  if "!errorlevel!" NEQ 0 (
    set "MESSAGE=!RES_ERR_CMD! docker compose up -d"
    goto :error
  )
  call :wait_postgres
  if "!errorlevel!" NEQ 0 goto :error
)

if "%DO_IMAGES%"=="0" (
  call "%DIR_SCRIPT%startdown.bat" "%proyecto%" "%CHECK%" "STOP"
  if "!errorlevel!" NEQ 0 (
    set "MESSAGE=!RES_ERR_CMD! docker compose stop"
    goto :error
  )
  call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%SQL%"
  if "!errorlevel!" NEQ 0 (
    set "MESSAGE=!RES_ERR_CMD! docker compose up postgres"
    goto :error
  )
)

set "MESSAGE=!RES_DB_RESTORE! %DUMPALL_FILE%!"
call :logger !LOG-INFO! "!MESSAGE!"
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -v ON_ERROR_STOP=1 -U "%DB_HOSTNAME%" -d "%DB_HOSTNAME%" < "%DUMPALL_FILE%" >nul 2>&1
if %errorlevel% NEQ 0 (
  set "MESSAGE=!RES_ERR_CMD! psql dumpall"
  goto :error
)

if exist "%BACKUP_PATH%\trytond" (
  for /f "tokens=*" %%i in ('docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps "%SERVER%" --format "{{.Names}}"') do set "CONT_APP=%%i"
  set "MESSAGE=!RES_STOP_APP!"
  call :logger !LOG-INFO! "!MESSAGE!"
  call "%DIR_SCRIPT%startdown.bat" "%proyecto%" "%INS%" "STOP"
  set "MESSAGE=!RES_FILES_COPY! %BACKUP_PATH%\trytond"
  call :logger !LOG-INFO! "!MESSAGE!"
  docker cp "%BACKUP_PATH%\trytond\." "!CONT_APP!:/var/lib/trytond/"
  if !errorlevel! NEQ 0 (
    set "MESSAGE=!RES_ERR_CMD! docker cp trytond"
    goto :error
  )
  set "MESSAGE=!RES_START_APP!"
  call :logger !LOG-INFO! "!MESSAGE!"
  call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%INS%"
)

goto :exit

:wait_postgres
  set /a "attempts=1"
  :wait_pg_loop
  <nul set /p=.
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" pg_isready -U "%DB_HOSTNAME%" >nul 2>&1
  if %errorlevel% equ 0 exit /b
  if %attempts% GEQ %max_attempts% (
    set "msg_cont=%proyecto% - !WORD_SERVICE! : %POSTGRES%" 
    set "MESSAGE=!RES_WAIT_DB3:PROYECTO=%msg_cont%!"
    exit /b 1
  )
  set /a attempts+=1
  set "MESSAGE=!RES_WAIT_DB1! %attempts%"
  call :logger !LOG-INFO! "!MESSAGE!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
  goto :wait_pg_loop

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:error
  echo.
  call :logger !LOG-ERROR! "!MESSAGE!"
  echo.
  pause 
  endlocal
  exit /b 1

:exit
  endlocal
  exit /b 0
