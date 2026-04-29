@echo off
REM ===============================================================================
REM PROGRAM:   restore_docker.bat
REM PROJECT:   Tryton Docker Manager
REM AUTHOR: Telepieza
REM COLLABORATOR: Gemini (Google AI)
REM VERSION:   1.1.25
REM DATE:     29/04/2026
REM LICENSE:   MIT License
REM DESCRIPTION: Database Hot-Import (Importar imágenes y Base de datos (RESTORE)
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
set "file_err=%DIR_TMP%\trytond_restore_err.txt"
set "file_tmp=%DIR_TMP%\trytond_restore_tmp.txt"

call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call "%DIR_SCRIPT%message.bat" "%APP%" "restore_docker"
call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!RES_STEP1!"

if "%DO_IMAGES%"=="1" (
  call "%DIR_SCRIPT%startdown.bat" "%proyecto%" "%CHECK%" "DOWN"
  if !errorlevel! NEQ 0 call "%DIR_SCRIPT%message.bat" "!LOG-WARN!" "!RES_ERR_CMD! !errorlevel! !WORD_DOCKER! !WORD_COMPOSE! DOWN"
  set "work_tar=!BACKUP_PATH!\img_postgres.tar"
  call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!RES_STEP2! !work_tar!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
  ver > nul
  docker load -i "!work_tar!"
  if !errorlevel! NEQ 0 (
    set "MESSAGE=1.-!RES_ERR_CMD! !errorlevel! !WORD_DOCKER! !WORD_LOAD! !work_tar!"
    goto :error
  )
  set "work_tar=!BACKUP_PATH!\img_tryton.tar"
  call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!RES_STEP2! !work_tar!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
  ver > nul
  docker load -i "!work_tar!"
  if !errorlevel! NEQ 0 (
    set "MESSAGE=2.-!RES_ERR_CMD! !errorlevel! !WORD_DOCKER! !WORD_LOAD! !work_tar!"
    goto :error
  )
  call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!RES_STEP3!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
  ver > nul
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" up -d
  if !errorlevel! NEQ 0 (
    set "MESSAGE=3.-!RES_ERR_CMD! !errorlevel! !WORD_DOCKER! !WORD_COMPOSE! up -d"
    goto :error
  )
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
  call :wait_postgres
  if !errorlevel! NEQ 0 goto :error
)

call "%DIR_SCRIPT%startdown.bat" "%proyecto%" "%CHECK%" "STOP"
if !errorlevel! NEQ 0 (
  set "MESSAGE=4.-!RES_ERR_CMD! !WORD_DOCKER! !WORD_COMPOSE! stop"
  goto :error
)
call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%SQL%"
if !errorlevel! NEQ 0 (
  set "MESSAGE=5.-!RES_ERR_CMD! !WORD_DOCKER! !WORD_COMPOSE! up %POSTGRES%"
  goto :error
)

set "MESSAGE=!RES_DB_RESTORE! %DUMPALL_FILE%!"
call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!MESSAGE!"
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
if exist "!file_tmp!" del "!file_tmp!" >nul
if exist "!file_err!" del "!file_err!" >nul
docker exec "!CURRENT_POSTGRES!" psql -U "%DB_HOSTNAME%" -tAc "SELECT 1 FROM pg_database WHERE datname='%DB_NAME%'" | findstr "1" >nul
if !errorlevel! NEQ 0 docker exec "!CURRENT_POSTGRES!" createdb -U "%DB_HOSTNAME%" "%DB_NAME%" >nul 2>&1
findstr /i /m /c:"%DB_NAME_DEMO%" "!DUMPALL_FILE!" >nul
if !errorlevel! EQU 0 (
  docker exec "!CURRENT_POSTGRES!" psql -U "%DB_HOSTNAME%" -tAc "SELECT 1 FROM pg_database WHERE datname='%DB_NAME_DEMO%'" | findstr "1" >nul
  if !errorlevel! NEQ 0 docker exec "!CURRENT_POSTGRES!" createdb -U "%DB_HOSTNAME%" "%DB_NAME_DEMO%" >nul 2>&1
)
ver > nul
docker cp "!DUMPALL_FILE!" "!CURRENT_POSTGRES!:/tmp/restore.sql"
docker exec -i "!CURRENT_POSTGRES!" psql -v ON_ERROR_STOP=1 -U "%DB_HOSTNAME%" -d postgres -f /tmp/restore.sql >"%file_tmp%" 2>"%file_err%"
set "PSQL_ERR=!errorlevel!"
docker exec "!CURRENT_POSTGRES!" rm /tmp/restore.sql >nul 2>&1
if !PSQL_ERR! NEQ 0 (
  set "MESSAGE=6.-!RES_ERR_CMD! !PSQL_ERR! psql dumpall !CURRENT_POSTGRES! /tmp/restore.sql"
  goto :error
)

if exist "!file_tmp!" del "!file_tmp!" >nul
if exist "!file_err!" del "!file_err!" >nul
call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%CHECK%"
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "2"
call "%DIR_SCRIPT%status.bat" "%proyecto%" "%SEE%"
if exist "%BACKUP_PATH%\trytond" (
  set "MESSAGE=!RES_FILES_COPY! %BACKUP_PATH%\trytond"
  call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!MESSAGE!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
  docker cp "%BACKUP_PATH%\trytond\." "%CURRENT_TRYTON%:/var/lib/trytond/"
  if !errorlevel! NEQ 0 (
    set "MESSAGE=7.-!RES_ERR_CMD! !WORD_DOCKER! cp trytond:  %BACKUP_PATH%\trytond\ to %CURRENT_TRYTON%:/var/lib/trytond/"
    goto :error
  )
  set "MESSAGE=!RES_START_APP!"
  call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!MESSAGE!"
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
  call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!MESSAGE!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
  goto :wait_pg_loop

:error
  echo.
  call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!MESSAGE!"
  echo.
  pause 
  endlocal
  exit /b 1

:exit
  endlocal
  exit /b 0
