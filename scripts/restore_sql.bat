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
set /a "wait_timeres2=20"
set "log_action=!LOG-INFO!"
set "file_err=%DIR_TMP%\trytond_restore_err.txt"
set "file_tmp=%DIR_TMP%\trytond_restore_tmp.txt"

call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call :logger "%APP%" "restore_sql"

if /i "%back_action%"=="%INS%"  set "log_action=%INS%"

call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "2"
call "%DIR_SCRIPT%status.bat" "%proyecto%" "%SQL%"
if %errorlevel% EQU 0 (
  call "%DIR_SCRIPT%startdown.bat" "%proyecto%" "%CHECK%" "STOP"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres2!" "1"
  call "%DIR_SCRIPT%status.bat" "%proyecto%" "%CHECK%"
) 

if %errorlevel% NEQ 0 (
  call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%SQL%"
  if %errorlevel% NEQ 0 (
    call :logger "%INS%" "!STAT_START!"
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
    call "%DIR_SCRIPT%status.bat" "%proyecto%" "%CHECK%"
  )
)

set "DB_RESTORE=%DB_NAME%"
echo "%DUMPALL_FILE%" | findstr /i "demo" >nul
if %errorlevel% equ 0 set "DB_RESTORE=%DB_NAME_DEMO%"

if /i "%DO_MODE%"=="schema" set "MESSAGE=!RES_SCHEMA_RESTORE:DB=%DB_RESTORE%!"
if /i "%DO_MODE%"=="data" set "MESSAGE=!RES_DATA_RESTORE:DB=%DB_RESTORE%!"
if /i "%DO_MODE%"=="full_db" set "MESSAGE=!RES_FULLDB_RESTORE:DB=%DB_RESTORE%!"
call :logger "%INS%" "!MESSAGE! !DUMPALL_FILE!"
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres2!" "1"

if /i "%DO_MODE%"=="schema" (
  call :logger "%INS%" "!INSTALL_MODU_HEAD14! %DB_RESTORE%" "3"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" dropdb -U "%DB_HOSTNAME%" --if-exists "%DB_RESTORE%"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
  call :logger "%INS%" "!INSTALL_MODU_HEAD15! %DB_RESTORE%" "3"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" createdb -U "%DB_HOSTNAME%" "%DB_RESTORE%"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -v ON_ERROR_STOP=1 -U "%DB_HOSTNAME%" -d "%DB_RESTORE%" < "%DUMPALL_FILE%" >nul 2>%file_err%
  if !errorlevel! NEQ 0 (
    set "MESSAGE=!RES_ERR_CMD! %DO_MODE%"
    goto :error
  )
  call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%CHECK%"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "2"
  set "cmd=SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';"
  call :verify_database "tables" "!cmd!" "!DB_RESTORE!" "!DUMPALL_FILE!" "!RES_SCHEMA_RESTORE_2!" "YES"
  pause & goto :exit
)

if /i "%DO_MODE%"=="data" (
  call :logger "%INS%" "!RES_TABLE_TRUNCATE! %DB_RESTORE%" "3"
  set "clean_sql=%DIR_TMP%\tryton_clean_data.sql"
  (
    echo SET session_replication_role = replica;
    echo DO $$ DECLARE r RECORD; BEGIN 
    echo   FOR r IN ^(SELECT tablename FROM pg_tables WHERE schemaname = 'public'^) LOOP 
    echo     RAISE NOTICE 'Truncate table: %%', r.tablename;
    echo     EXECUTE 'TRUNCATE TABLE public.' ^|^| quote_ident^(r.tablename^) ^|^| ' CASCADE;'; 
    echo   END LOOP; 
    echo END $$;
  ) > "!clean_sql!"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -v ON_ERROR_STOP=1 -U "%DB_HOSTNAME%" -d "%DB_RESTORE%" < "!clean_sql!"
  if !errorlevel! NEQ 0 (
    if exist "!clean_sql!" del "!clean_sql!" >nul
    set "MESSAGE=!RES_ERR_CMD! !WORD_TRUNCATE! !WORD_DATA!"
    goto :error
  )
  if exist "!clean_sql!" del "!clean_sql!" >nul
  set "header_sql=%DIR_TMP%\tryton_header.sql"
  (
    echo BEGIN;
    echo SET session_replication_role = replica;
  ) > "!header_sql!"
  call :logger "%INS%" "!RES_WAIT_DATA!"
  cmd /c "type "!header_sql!" & type "%DUMPALL_FILE%" & echo. & echo COMMIT;" | docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -v ON_ERROR_STOP=1 -q -U "%DB_HOSTNAME%" -d "%DB_RESTORE%" >nul 2>%file_err%
  if !errorlevel! NEQ 0 (
    if exist "!header_sql!" del "!header_sql!" >nul
    set "MESSAGE=!RES_ERR_CMD! %DO_MODE%"
    goto :error
  )
  if exist "!header_sql!" del "!header_sql!" >nul
  call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%CHECK%"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "2"
  set "cmd=SELECT count(*) FROM ir_module;"
  call :verify_database "modules" "!cmd!" "!DB_RESTORE!" "!DUMPALL_FILE!" "!RES_DATA_RESTORE_2!"
  call "%DIR_SCRIPT%status.bat" "%proyecto%" "%SEE%"
  echo.
  pause & goto :exit
)

if /i "%DO_MODE%"=="full_db" (
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" pg_restore -e -U "%DB_HOSTNAME%" -d "%DB_RESTORE%" --clean --if-exists < "%DUMPALL_FILE%" >nul 2>%file_err%
  if !errorlevel! NEQ 0 (
      set "MESSAGE=!RES_ERR_CMD! %DO_MODE%"
      goto :error
  )
  call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%CHECK%"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "2"
  set "cmd=SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';"
  call :verify_database "tables" "!cmd!" "!DB_RESTORE!" "!DUMPALL_FILE!" "!RES_SCHEMA_RESTORE_2!"
  set "cmd=SELECT count(*) FROM ir_module;"
  call :verify_database "modules" "!cmd!" "!DB_RESTORE!" "!DUMPALL_FILE!" "!RES_DATA_RESTORE_2!" "YES"
  call "%DIR_SCRIPT%status.bat" "%proyecto%" "%SEE%"
  echo.
  pause & goto :exit
)

goto :exit

:verify_database
  set "ve_label=%~1"
  set "ve_cmd=%~2"
  set "ve_database=%~3"
  set "ve_file_sql=%~4"
  set "ve_message=%~5"
  set "ve_status=%~6"
  set "MESSAGE=!ve_message:DB=%ve_database%!"
  call :logger "!log_action!" "!MESSAGE! !ve_file_sql!"
  if exist "!file_tmp!" del "!file_tmp!" >nul
  if exist "!file_err!" del "!file_err!" >nul
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%POSTGRES%" "!ve_cmd!" "!ve_database!" "!file_tmp!" "!file_err!" "" "!ve_label!" "!RES_SUCCESS!"
  if /i "%ve_status%"=="YES" (
    echo.
    call "%DIR_SCRIPT%status.bat" "%proyecto%" "%SEE%"
    echo.
  )
  exit /b

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
