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
set "file_err=%DIR_TMP%\trytond_restore_err.txt"
set "file_tmp=%DIR_TMP%\trytond_restore_tmp.txt"

call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call :logger "%APP%" "restore_sql"

call "%DIR_SCRIPT%status.bat" "%proyecto%" "%SQL%"
if %errorlevel% EQU 0 (
  call "%DIR_SCRIPT%startdown.bat" "%proyecto%" "%CHECK%" "STOP"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
  call "%DIR_SCRIPT%status.bat" "%proyecto%" "%CHECK%"
) 

if %errorlevel% NEQ 0 (
  call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%SQL%"
  if %errorlevel% NEQ 0 (
    call :logger "%INS%" "!STAT_START!"
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1" "N"
    call "%DIR_SCRIPT%status.bat" "%proyecto%" "%CHECK%"
  )
)

set "DB_RESTORE=%DB_NAME%"
echo "%DUMPALL_FILE%" | findstr /i "demo" >nul
if %errorlevel% equ 0 set "DB_RESTORE=%DB_NAME_DEMO%"

if /i "%DO_MODE%"=="schema" set "MESSAGE=!RES_SCHEMA_RESTORE:DB=%DB_RESTORE%!"
if /i "%DO_MODE%"=="data" set "MESSAGE=!RES_DATA_RESTORE:DB=%DB_RESTORE%!"
if /i "%DO_MODE%"=="full_db" set "MESSAGE=!RES_FULLDB_RESTORE:DB=%DB_RESTORE%!"
call :logger "%INS%" "!MESSAGE! %DUMPALL_FILE%"

if /i "%DO_MODE%"=="data" (
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -v ON_ERROR_STOP=1 -U "%DB_HOSTNAME%" -d "%DB_RESTORE%" < "%DUMPALL_FILE%" >nul 2>%file_err%
  if !errorlevel! NEQ 0 (
    call :logger !LOG-ERROR! "!RES_ERR_CMD! %DO_MODE%"
    goto :error
  )
  call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%CHECK%"
  set "MESSAGE=!RES_DATA_RESTORE_2:DB=%DB_RESTORE%!"
  call :logger "%INS%" "!MESSAGE! !DUMPALL_FILE!"
  set "cmd=SELECT count(*) FROM ir_module;"
  call :run_trytond_sql "%POSTGRES%" "!cmd!" "%file_tmp%" "%file_err%" "" "modules"
  echo.
  call "%DIR_SCRIPT%status.bat" "%proyecto%" "%SEE%"
  echo.
  pause & goto :exit
)

if /i "%DO_MODE%"=="schema" (
  call :logger "%INS%" "!INSTALL_MODU_HEAD14! %DB_RESTORE%" "3"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" dropdb -U "%DB_HOSTNAME%" --if-exists "%DB_RESTORE%"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
  call :logger "%INS%" "!INSTALL_MODU_HEAD15! %DB_RESTORE%" "3"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" createdb -U "%DB_HOSTNAME%" "%DB_RESTORE%"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -v ON_ERROR_STOP=1 -U "%DB_HOSTNAME%" -d "%DB_RESTORE%" < "%DUMPALL_FILE%" >nul 2>%file_err%
  if !errorlevel! NEQ 0 (
    call :logger !LOG-ERROR! "!RES_ERR_CMD! %DO_MODE%"
    goto :error
  )
  call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%CHECK%"
  set "MESSAGE=!RES_SCHEMA_RESTORE_2:DB=%DB_RESTORE%!"
  call :logger "%INS%" "!MESSAGE! !DUMPALL_FILE!"
  set "cmd=SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';"
  call :run_trytond_sql "%POSTGRES%" "!cmd!" "%file_tmp%" "%file_err%" "" "tables"
  echo.
  call "%DIR_SCRIPT%status.bat" "%proyecto%" "%SEE%"
  echo.
  pause & goto :exit
)

if /i "%DO_MODE%"=="full_db" (
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" pg_restore -e -U "%DB_HOSTNAME%" -d "%DB_RESTORE%" --clean --if-exists < "%DUMPALL_FILE%" >nul 2>%file_err%
  if !errorlevel! NEQ 0 (
    call :logger !LOG-ERROR! "!RES_ERR_CMD! %DO_MODE%"
    goto :error
  )
  call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%CHECK%"
  set "MESSAGE=!RES_SCHEMA_RESTORE_2:DB=%DB_RESTORE%!"
  call :logger "%INS%" "!MESSAGE! !DUMPALL_FILE!"
  set "cmd=SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';"
  call :run_trytond_sql "%POSTGRES%" "!cmd!" "%file_tmp%" "%file_err%" "" "tables"
   set "MESSAGE=!RES_DATA_RESTORE_2:DB=%DB_RESTORE%!"
  call :logger "%INS%" "!MESSAGE! !DUMPALL_FILE!"
  set "cmd=SELECT count(*) FROM ir_module;"
  call :run_trytond_sql "%POSTGRES%" "!cmd!" "%file_tmp%" "%file_err%" "" "modules"
  echo.
  call "%DIR_SCRIPT%status.bat" "%proyecto%" "%SEE%"
  echo.
  pause & goto :exit
)

goto :exit

:run_trytond_sql
   set "servicio=%~1"
   set "cmd=%~2"
   set "logfile=%~3"
   set "errfile=%~4"
   set "add=%~5"
   set "label=%~6"
   if not "%logfile%"=="" if /i not "%add%"=="YES" if exist "%logfile%" del "%logfile%" >nul
   if not "%errfile%"=="" if /i not "%add%"=="YES" if exist "%errfile%" del "%errfile%" >nul
   set "redir_out="
   set "redir_err="
   if not "%logfile%"=="" ( 
     if /i "%add%"=="YES" (
      set "redir_out=>>"%logfile%""
     ) else (
      set "redir_out=>"%logfile%""
     )
  )
  if not "%errfile%"=="" (
      if /i "%add%"=="YES" (
         set "redir_err=2>>"%errfile%""
      ) else (
         set "redir_err=2>"%errfile%""
      )
  )
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U postgres -d "!DB_RESTORE!" -At -c "%cmd%" %redir_out% %redir_err%
  set "status=%ERRORLEVEL%"
  if %status% EQU 0 (
     call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
     if exist "%logfile%" set /p count=<"%logfile%"
     call :logger "!LOG-SUCC!" "!RES_SUCCESS! !DB_RESTORE! (!count! !label!)"
    exit /b 0
  )
  if %status% NEQ 0 (
     if exist "%errfile%" if not "%errfile%"=="" (
       call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "display_file_event_all %label%"!LOG-ERROR!" "%errfile%"
       exit /b %status%
     )
     if exist "%logfile%" if not "%logfile%"=="" (
      call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "display_file_event_all %label%" "!LOG-INFO!" "%logfile%"
      exit /b %status%
     )
  )
  exit /b 0

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
