@echo off
REM ===============================================================================
REM PROGRAM:   restore_sql.bat
REM PROJECT:   Tryton Docker Manager
REM AUTHOR: Telepieza
REM COLLABORATOR: Gemini (Google AI)
REM VERSION:   1.0.0
REM DATE:      23/03/2026
REM LICENSE:   MIT License
REM DESCRIPTION: Database Hot-Import - Import file sql (RESTORE)
REM ==============================================================================
setlocal enabledelayedexpansion
chcp 65001 >nul
set "proyecto=%~1"
set "BACKUP_PATH=%~2"
set "DO_IMAGES=%~3"
set "DUMPALL_FILE=%~4"
set "DO_MODE=%~5"
set /a "attempts=0"
set /a "max_attempts=10"
set /a "wait_timeres=10"

set /a "num_error=0"
set "ZIP_PATH="
call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call :logger "%APP%" "restore_sql"

call "%DIR_SCRIPT%status.bat" "%proyecto%" "%CHECK%"
if %errorlevel% NEQ 0 (
  call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%CHECK%"
  if %errorlevel% NEQ 0 (
    call :logger "%LOG-INFO%" "!STAT_START!"
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
    call "%DIR_SCRIPT%status.bat" "%proyecto%" "%CHECK%"
  )
)

set "DB_RESTORE=%DB_NAME%"
echo "%DUMPALL_FILE%" | findstr /i "demo" >nul
if %errorlevel% equ 0 set "DB_RESTORE=%DB_NAME_DEMO%"

call :logger "%INS%" "!INSTALL_MODU_HEAD14! %DB_RESTORE%" "3"
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" dropdb -U "%DB_HOSTNAME%" --if-exists "%DB_RESTORE%"
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
call :logger "%INS%" "!INSTALL_MODU_HEAD15! %DB_RESTORE%" "3"
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" createdb -U "%DB_HOSTNAME%" "%DB_RESTORE%"
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
call :logger "%INS%" "!INSTALL_MODU_HEAD16! %DB_RESTORE%" "3"
docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U "%DB_HOSTNAME%" -d "%DB_RESTORE%" -tA -c "SELECT current_database();" >nul 2>&1
if %errorlevel% NEQ 0 (
  set "MESSAGE=!BCK_CONT_STOP! %DB_RESTORE%"
  goto :error
)

call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
if /i "%DO_MODE%"=="schema" set "MESSAGE=!RES_SCHEMA_RESTORE:DB=%DB_RESTORE%!"
if /i "%DO_MODE%"=="data" set "MESSAGE=!RES_DATA_RESTORE:DB=%DB_RESTORE%!"
if /i "%DO_MODE%"=="full_db" set "MESSAGE=!RES_FULLDB_RESTORE:DB=%DB_RESTORE%!"
call :logger !LOG-INFO! "!MESSAGE! %DUMPALL_FILE%"
if /i "%DO_MODE%" NEQ "full_db" (
  type "%DUMPALL_FILE%" | docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -v ON_ERROR_STOP=1 -U "%DB_HOSTNAME%" -d "%DB_RESTORE%" >nul 2>&1
) else (
  type "%DUMPALL_FILE%" | docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" pg_restore -e -U "%DB_HOSTNAME%" -d "%DB_RESTORE%" --clean --if-exists >nul 2>&1
)
if %errorlevel% NEQ 0 call :logger !LOG-ERROR! "!RES_ERR_CMD! %DO_MODE%" 
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
goto :exit

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
