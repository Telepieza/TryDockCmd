
@echo off
:: =========================================================================================
:: PROGRAM:   restore.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    [Telepieza - Mariano Vallespín]
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      01/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Disaster Recovery
:: =========================================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: Analiza si la llamada es del tcd.bat
set "proyecto=%~1"
set "base_backup_dir=%~2"
set /a "attempts=0"
set /a "max_attempts=10"
set /a "wait_timeres=5"
call "%DIR_SCRIPT%startcontrol.bat" %proyecto%
call :logger %APP% "restore"
:: mensajes visualizados en consola
call :logger !LOG-INFO! "!RES_WARN!"

:menu_restore
  echo.
  set "type="
  set "subfolder="
  echo "!RES_MENU_TITLE!"
  call :logger %TXT% "!RES_OPT1!"
  call :logger %TXT% "!RES_OPT2!"
  call :logger %TXT% "!RES_OPT3!"
  echo.
  set /p "type=!RES_PROMPT!"
  if "%type%"=="1" goto :full_restore
  if "%type%"=="2" goto :data_restore
  if "%type%"=="3" goto :end_restore
  call :logger !LOG-ERROR! "!RES_ERR_OPT!"
  goto :menu_restore

:end_restore
  call :logger !LOG-INFO! "!RES_ENDING!"
  goto :exit

:full_restore
  echo.
  set "MESSAGE=!RES_LIST:DIRECTORY=%base_backup_dir%!"
  call :logger !LOG-INFO! "!MESSAGE!"
  dir "%base_backup_dir%" /b /ad
  echo.
  set /p "subfolder=!RES_DIR_PROMPT!"
  set "BACKUP_PATH=%base_backup_dir%\%subfolder%"
  if not exist "%BACKUP_PATH%" (
     set "MESSAGE=!RES_ERR_DIR:FOLDER=%BACKUP_PATH%!"
     call :logger !LOG-ERROR! "!MESSAGE!"
     goto :menu_restore
  )
  call :logger !LOG-INFO! "!RES_STEP1!"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" down
  call :logger !LOG-INFO! "!RES_STEP2!"
  if exist "%BACKUP_PATH%\img_postgres.tar" docker load < "%BACKUP_PATH%\img_postgres.tar"
  if exist "%BACKUP_PATH%\img_tryton.tar" docker load < "%BACKUP_PATH%\img_tryton.tar"
  call :logger !LOG-INFO! "!RES_STEP3!"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p %proyecto% up -d
  :: Salto directo a la restauracion de la SQL una vez levantados los contenedores nuevos
  goto :process_sql

:data_restore
  echo.
  set "MESSAGE=!RES_ERR_DIR:DIRECTORY=%base_backup_dir%!"
  call :logger !LOG-INFO! "!MESSAGE!"
  dir "%base_backup_dir%" /b /ad
  set /p "subfolder=!RES_DIR_PROMPT!"
  set "BACKUP_PATH=%base_backup_dir%\%subfolder%"
  if not exist "%BACKUP_PATH%" (
     set "MESSAGE=!RES_ERR_DIR:FOLDER=%BACKUP_PATH%!"
     call :logger !LOG-ERROR! "!MESSAGE!"
     goto :menu_restore
  )
  :: Para restaurar la SQL, los contenedores deben estar activos
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" --status running -q | findstr "^" >nul 2>&1
  if %errorlevel% neq 0 (
    call :logger !LOG-INFO! "!RES_STARTING!"
    docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" up -d
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "20" "1"
  )

:process_sql
  :: Localizar el contenedor de la DB dinamicamente
  for /f "tokens=*" %%i in ('docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%"  ps "%POSTGRES%" --format "{{.Names}}"') do set "CONT_DB=%%i"
  for /f "tokens=*" %%i in ('docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%"  ps "%SERVER%"   --format "{{.Names}}"') do set "CONT_APP=%%i"
  set "msg_cont=%BACKUP_PATH%\tryton_db_data.sql"
  set "MESSAGE=!RES_SQL_DOING:FILE=%msg_cont%!"
  call :logger !LOG-ERROR! "!MESSAGE!"
  set /a "attempts=1"
  :: Usamos 'cat' (vía docker exec) o redirección de psql para inyectar el SQL
  if exist "%msg_cont%" (
     call :wait_postgres
     if %attempts% GEQ %max_attempts% (
       call :logger !LOG-ERROR! "!RES_WAIT_DB2!"
       goto :exit
     )
    :: IMPORTANTE: psql -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" limpia la DB antes de restaurar
    docker exec -i "%CONT_DB%" psql -U "%POSTGRES%" -d "%POSTGRES%" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
    type "%msg_cont%" | docker exec -i "%CONT_DB%" psql -U "%POSTGRES%" -d "%POSTGRES%"
  )

  call :logger !LOG-INFO! "!RES_FILES_DOING!"
  set "msg_cont=%BACKUP_PATH%\tryton_files"
  if exist "%msg_cont%" (
    :: Copiamos el contenido de la carpeta backup a la ruta del servidor
    docker cp "%msg_cont%/." %CONT_APP%:/var/lib/trytond/db/
  )

  call :logger !LOG-INFO! "!RES_RESTART!"
  docker compose -p "%proyecto%" restart
  set "MESSAGE=!RES_SUCCESS:FOLDER=%subfolder%!"
  call :logger !LOG-SUCC! "!MESSAGE!"
  goto :exit

:wait_postgres
  <nul set /p=.
  :: Usamos 'docker exec' para analizar la base de datos
  docker exec "%CONT_DB%" pg_isready -U "!DB_USER!" >nul 2>&1
  if %errorlevel% equ 0 exit /b
  if %attempts% GEQ %max_attempts% (
    set "msg_cont=%proyecto% - !WORD_SERVICE! : %CONT_DB%" 
    set "MESSAGE=!RES_WAIT_DB3:PROYECTO=%msg_cont%!"
    exit /b
  )
  set /a attempts+=1
  set "MESSAGE=!RES_WAIT_DB1:COUNT=%attempts%!"
  call :logger !LOG-INFO! "!MESSAGE!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
  goto :wait_postgres

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2"
  exit /b

:exit
  :: Devolvemos el control al menu
  endlocal
  exit /b 0
