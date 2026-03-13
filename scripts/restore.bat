@echo off
:: =========================================================================================
:: PROGRAM:   restore.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    [Telepieza - Mariano Vallespin]
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.1.0
:: DATE:      12/03/2026
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
set "file_err=%DIR_TMP%\restore_err.txt"
set "file_tmp=%DIR_TMP%\restore_tmp.txt"
set "restore_root=%DIR_TMP%\restore"
set "EXIT_CODE=0"
set "DB_SUPER=postgres"
set "DB_ADMIN_DB=postgres"
call "%DIR_SCRIPT%startcontrol.bat" %proyecto%
call :logger %APP% "restore"

if "%base_backup_dir%"=="" set "base_backup_dir=%DIR_BACKUP%"
if "!DB_NAME!"=="" set "DB_NAME=%TRYTON%"
if /i "!TRYTON_DB_DEMO!"=="" set "TRYTON_DB_DEMO=%DB_NAME_DEMO%"
if /i "%DB_NAME_DEMO%" NEQ "%TRYTON_DB_DEMO%" set "DB_NAME_DEMO=%TRYTON_DB_DEMO%"
if not "%DB_SUPERUSER%"=="" set "DB_SUPER=%DB_SUPERUSER%"

:: mensajes visualizados en consola
call :logger !LOG-INFO! "!RES_WARN!"

:menu_restore
  echo.
  set "type="
  echo "!RES_MENU_TITLE!"
  call :logger %TXT% "!RES_OPT1!"
  call :logger %TXT% "!RES_OPT2!"
  call :logger %TXT% "!RES_OPT3!"
  call :logger %TXT% "!RES_OPT4!"
  call :logger %TXT% "!RES_OPT5!"
  call :logger %TXT% "!RES_OPT6!"
  echo.
  set /p "type=!RES_PROMPT!"
  if "%type%"=="1" set "DO_IMAGES=1" & set "DO_DUMPALL=1" & set "DO_FILES=1" & goto :full_restore
  if "%type%"=="2" set "DO_IMAGES=0" & set "DO_DUMPALL=1" & set "DO_FILES=1" & goto :full_restore
  if "%type%"=="3" set "MODE=schema" & goto :schema_data_restore
  if "%type%"=="4" set "MODE=data" & goto :schema_data_restore
  if "%type%"=="5" set "MODE=full_db" & goto :schema_data_restore
  if "%type%"=="6" goto :end_restore
  call :logger !LOG-ERROR! "!RES_ERR_OPT!"
  goto :menu_restore

:end_restore
  call :logger !LOG-INFO! "!RES_ENDING!"
  goto :exit

:full_restore
  call :select_backup_zip
  if errorlevel 1 goto :menu_restore
  call :validate_full_backup
  if errorlevel 1 goto :menu_restore

  call :logger !LOG-INFO! "!RES_STEP1!"
  if "%DO_IMAGES%"=="1" (
    docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" down
    call :check_error "docker compose down"
  )

  if "%DO_IMAGES%"=="1" (
    call :logger !LOG-INFO! "!RES_STEP2!"
    if exist "%BACKUP_PATH%\img_postgres.tar" docker load < "%BACKUP_PATH%\img_postgres.tar"
    if errorlevel 1 (
      call :fail "!RES_ERR_CMD:CMD=docker load img_postgres.tar!"
      goto :exit
    )
    if exist "%BACKUP_PATH%\img_tryton.tar" docker load < "%BACKUP_PATH%\img_tryton.tar"
    if errorlevel 1 (
      call :fail "!RES_ERR_CMD:CMD=docker load img_tryton.tar!"
      goto :exit
    )
  )

  call :logger !LOG-INFO! "!RES_STEP3!"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p %proyecto% up -d
  call :check_error "docker compose up -d"
  call :wait_postgres
  if errorlevel 1 goto :exit

  if "%DO_DUMPALL%"=="1" call :restore_dumpall
  if errorlevel 1 goto :exit
  if "%DO_FILES%"=="1" call :restore_files
  if errorlevel 1 goto :exit

  call :logger !LOG-INFO! "!RES_RESTART!"
  docker compose -p "%proyecto%" restart
  call :check_error "docker compose restart"
  set "MESSAGE=!RES_SUCCESS:FOLDER=%BACKUP_PATH%!"
  call :logger !LOG-SUCC! "!MESSAGE!"
  call :cleanup_restore
  goto :exit

:schema_data_restore
  call :select_backup_source
  if errorlevel 1 goto :menu_restore

  :: Para restaurar la SQL, los contenedores deben estar activos
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps --status running -q | findstr "^" >nul 2>&1
  if %errorlevel% neq 0 (
    call :logger !LOG-INFO! "!RES_STARTING!"
    docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" up -d
    call :check_error "docker compose up -d"
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "20" "1"
  )

  call :wait_postgres
  if errorlevel 1 goto :exit
  call :restore_schema_data
  if errorlevel 1 goto :exit
  call :cleanup_restore
  goto :exit

:select_backup_zip
  echo.
  set "MESSAGE=!RES_LIST_ZIP:DIRECTORY=%base_backup_dir%!"
  call :logger !LOG-INFO! "!MESSAGE!"
  if not exist "%base_backup_dir%\*.zip" (
    call :logger !LOG-ERROR! "!RES_ERR_ZIP:FILE=%base_backup_dir%!"
    exit /b 1
  )
  dir "%base_backup_dir%\*.zip" /b
  echo.
  set /p "zip_name=!RES_ZIP_PROMPT!"
  set "ZIP_PATH=%base_backup_dir%\%zip_name%"
  if not exist "%ZIP_PATH%" (
     set "MESSAGE=!RES_ERR_ZIP:FILE=%ZIP_PATH%!"
     call :logger !LOG-ERROR! "!MESSAGE!"
     exit /b 1
  )
  call :expand_zip "%ZIP_PATH%"
  exit /b %errorlevel%

:select_backup_source
  echo.
  set "MESSAGE=!RES_LIST:DIRECTORY=%base_backup_dir%!"
  call :logger !LOG-INFO! "!MESSAGE!"
  dir "%base_backup_dir%" /b /ad
  if exist "%base_backup_dir%\*.zip" dir "%base_backup_dir%\*.zip" /b
  echo.
  set /p "subfolder=!RES_DIR_PROMPT!"
  set "BACKUP_PATH=%base_backup_dir%\%subfolder%"
  if /i "%subfolder:~-4%"==".zip" (
     set "ZIP_PATH=%base_backup_dir%\%subfolder%"
     if not exist "%ZIP_PATH%" (
        set "MESSAGE=!RES_ERR_ZIP:FILE=%ZIP_PATH%!"
        call :logger !LOG-ERROR! "!MESSAGE!"
        exit /b 1
     )
     call :expand_zip "%ZIP_PATH%"
     exit /b %errorlevel%
  )
  if not exist "%BACKUP_PATH%" (
     set "MESSAGE=!RES_ERR_DIR:FOLDER=%BACKUP_PATH%!"
     call :logger !LOG-ERROR! "!MESSAGE!"
     exit /b 1
  )
  exit /b 0

:expand_zip
  set "ZIP_PATH=%~1"
  for %%A in ("%ZIP_PATH%") do set "ZIP_BASE=%%~nA"
  set "RESTORE_PATH=%restore_root%\%ZIP_BASE%"
  if exist "%RESTORE_PATH%" rd /s /q "%RESTORE_PATH%" >nul 2>&1
  mkdir "%RESTORE_PATH%" >nul 2>&1
  set "MESSAGE=!RES_EXTRACT:FILE=%ZIP_PATH%!"
  call :logger !LOG-INFO! "!MESSAGE!"
  powershell -Command "$ProgressPreference='SilentlyContinue'; Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%RESTORE_PATH%' -Force"
  call :check_error "Expand-Archive"
  if exist "%RESTORE_PATH%\%ZIP_BASE%" (
     set "BACKUP_PATH=%RESTORE_PATH%\%ZIP_BASE%"
  ) else (
     set "BACKUP_PATH=%RESTORE_PATH%"
  )
  if not exist "%BACKUP_PATH%" exit /b 1
  exit /b 0

:validate_full_backup
  call :logger !LOG-INFO! "!RES_VALIDATE_ZIP!"
  set "DUMPALL_FILE="
  for %%F in ("%BACKUP_PATH%\*_dumpall.sql") do set "DUMPALL_FILE=%%F"
  if not defined DUMPALL_FILE (
    call :fail "!RES_REQUIRED_MISSING:FILE=*dumpall.sql!" 
    exit /b 1
  )
  call :require_file_size "%DUMPALL_FILE%"
  if errorlevel 1 exit /b 1
  set "FILES_PATH=%BACKUP_PATH%\trytond"
  if not exist "%FILES_PATH%" (
    call :fail "!RES_REQUIRED_MISSING:FILE=%FILES_PATH%!"
    exit /b 1
  )
  if "%DO_IMAGES%"=="1" (
    if not exist "%BACKUP_PATH%\img_postgres.tar" call :fail "!RES_REQUIRED_MISSING:FILE=img_postgres.tar!" & exit /b 1
    if not exist "%BACKUP_PATH%\img_tryton.tar" call :fail "!RES_REQUIRED_MISSING:FILE=img_tryton.tar!" & exit /b 1
  )
  exit /b 0

:restore_dumpall
  call :resolve_containers
  if not defined CONT_DB call :fail "!RES_CONT_DB_MISSING!" & exit /b 1
  if not defined DUMPALL_FILE for %%F in ("%BACKUP_PATH%\*_dumpall.sql") do set "DUMPALL_FILE=%%F"
  if not defined DUMPALL_FILE call :fail "!RES_SQL_NOT_FOUND:FOLDER=%BACKUP_PATH%!" & exit /b 1
  call :require_file_size "%DUMPALL_FILE%"
  if errorlevel 1 exit /b 1
  call :drop_db_if_exists "%DB_NAME%"
  if errorlevel 1 exit /b 1
  if not "%DB_NAME_DEMO%"=="" call :drop_db_if_exists "%DB_NAME_DEMO%"
  if errorlevel 1 exit /b 1
  set "MESSAGE=!RES_DB_RESTORE:FILE=%DUMPALL_FILE%!"
  call :logger !LOG-INFO! "!MESSAGE!"
  type "%DUMPALL_FILE%" | docker exec -i "%CONT_DB%" psql -v ON_ERROR_STOP=1 -U "%DB_SUPER%" -d "%DB_ADMIN_DB%"
  call :check_error "psql dumpall"
  exit /b %errorlevel%

:restore_files
  call :resolve_containers
  if not defined CONT_APP call :fail "!RES_CONT_APP_MISSING!" & exit /b 1
  set "FILES_PATH=%BACKUP_PATH%\trytond"
  if not exist "%FILES_PATH%" (
    set "MESSAGE=!RES_SRC_NOT_FOUND:FILE=%FILES_PATH%!"
    call :logger !LOG-WARN! "!MESSAGE!"
    exit /b 0
  )
  call :logger !LOG-INFO! "!RES_STOP_APP!"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" stop "%SERVER%"
  call :check_error "docker compose stop server"
  set "MESSAGE=!RES_FILES_COPY:FOLDER=%FILES_PATH%!"
  call :logger !LOG-INFO! "!MESSAGE!"
  docker cp "%FILES_PATH%/." %CONT_APP%:/var/lib/trytond/
  call :check_error "docker cp trytond"
  call :logger !LOG-INFO! "!RES_START_APP!"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" start "%SERVER%"
  call :check_error "docker compose start server"
  exit /b %errorlevel%

:restore_schema_data
  call :resolve_containers
  if /i "%MODE%"=="schema" (
    call :restore_schema "%DB_NAME%" "%BACKUP_PATH%\%DB_NAME%_schema.sql"
    if not "%DB_NAME_DEMO%"=="" if exist "%BACKUP_PATH%\%DB_NAME_DEMO%_schema.sql" call :restore_schema "%DB_NAME_DEMO%" "%BACKUP_PATH%\%DB_NAME_DEMO%_schema.sql"
    exit /b 0
  )
  if /i "%MODE%"=="data" (
    call :restore_data "%DB_NAME%" "%BACKUP_PATH%\%DB_NAME%_data.sql"
    if not "%DB_NAME_DEMO%"=="" if exist "%BACKUP_PATH%\%DB_NAME_DEMO%_data.sql" call :restore_data "%DB_NAME_DEMO%" "%BACKUP_PATH%\%DB_NAME_DEMO%_data.sql"
    exit /b 0
  )
  if /i "%MODE%"=="full_db" (
    call :restore_full_db "%DB_NAME%" "%BACKUP_PATH%\%DB_NAME%_full_db.sql"
    if not "%DB_NAME_DEMO%"=="" if exist "%BACKUP_PATH%\%DB_NAME_DEMO%_full_db.sql" call :restore_full_db "%DB_NAME_DEMO%" "%BACKUP_PATH%\%DB_NAME_DEMO%_full_db.sql"
    exit /b 0
  )
  exit /b 1

:restore_schema
  set "DBN=%~1"
  set "FILE=%~2"
  if not exist "%FILE%" (
    set "MESSAGE=!RES_SRC_NOT_FOUND:FILE=%FILE%!"
    call :logger !LOG-ERROR! "!MESSAGE!"
    exit /b 1
  )
  call :require_file_size "%FILE%"
  if errorlevel 1 exit /b 1
  call :recreate_db "%DBN%"
  if errorlevel 1 exit /b 1
  set "MESSAGE=!RES_SCHEMA_RESTORE:DB=%DBN% FILE=%FILE%!"
  call :logger !LOG-INFO! "!MESSAGE!"
  type "%FILE%" | docker exec -i "%CONT_DB%" psql -v ON_ERROR_STOP=1 -U "%DB_SUPER%" -d "%DBN%"
  call :check_error "psql schema"
  exit /b %errorlevel%

:restore_data
  set "DBN=%~1"
  set "FILE=%~2"
  if not exist "%FILE%" (
    set "MESSAGE=!RES_SRC_NOT_FOUND:FILE=%FILE%!"
    call :logger !LOG-ERROR! "!MESSAGE!"
    exit /b 1
  )
  call :require_file_size "%FILE%"
  if errorlevel 1 exit /b 1
  call :ensure_db_exists "%DBN%" "skip"
  if errorlevel 1 exit /b 1
  set "MESSAGE=!RES_DATA_RESTORE:DB=%DBN% FILE=%FILE%!"
  call :logger !LOG-INFO! "!MESSAGE!"
  type "%FILE%" | docker exec -i "%CONT_DB%" psql -v ON_ERROR_STOP=1 -U "%DB_SUPER%" -d "%DBN%"
  call :check_error "psql data"
  exit /b %errorlevel%

:restore_full_db
  set "DBN=%~1"
  set "FILE=%~2"
  if not exist "%FILE%" (
    set "MESSAGE=!RES_SRC_NOT_FOUND:FILE=%FILE%!"
    call :logger !LOG-ERROR! "!MESSAGE!"
    exit /b 1
  )
  call :require_file_size "%FILE%"
  if errorlevel 1 exit /b 1
  call :recreate_db "%DBN%"
  if errorlevel 1 exit /b 1
  set "MESSAGE=!RES_FULLDB_RESTORE:DB=%DBN% FILE=%FILE%!"
  call :logger !LOG-INFO! "!MESSAGE!"
  type "%FILE%" | docker exec -i "%CONT_DB%" pg_restore -e -U "%DB_SUPER%" -d "%DBN%" --clean --if-exists
  call :check_error "pg_restore"
  exit /b %errorlevel%

:ensure_db_exists
  set "DBN=%~1"
  set "MODE_CREATE=%~2"
  set "DB_EXISTS="
  if exist "%file_tmp%" del "%file_tmp%" >nul
  docker exec -i "%CONT_DB%" psql -U "%DB_SUPER%" -d "%DB_ADMIN_DB%" -tA -c "SELECT 1 FROM pg_catalog.pg_database WHERE datname='%DBN%';" >"%file_tmp%" 2>nul
  for /f "usebackq tokens=*" %%D in ("%file_tmp%") do set "DB_EXISTS=%%D"
  if "%DB_EXISTS%"=="1" exit /b 0
  if /i "%MODE_CREATE%"=="create" (
    set "MESSAGE=!RES_DB_CREATE:DB=%DBN%!"
    call :logger !LOG-INFO! "!MESSAGE!"
    docker exec -i "%CONT_DB%" createdb -U "%DB_SUPER%" "%DBN%"
    call :check_error "createdb"
    exit /b %errorlevel%
  )
  set "MESSAGE=!RES_DB_MISSING:DB=%DBN%!"
  call :logger !LOG-WARN! "!MESSAGE!"
  exit /b 1

:recreate_db
  set "DBN=%~1"
  call :drop_db_if_exists "%DBN%"
  if errorlevel 1 exit /b 1
  set "MESSAGE=!RES_DB_CREATE:DB=%DBN%!"
  call :logger !LOG-INFO! "!MESSAGE!"
  docker exec -i "%CONT_DB%" createdb -U "%DB_SUPER%" "%DBN%"
  call :check_error "createdb"
  exit /b %errorlevel%

:drop_db_if_exists
  set "DBN=%~1"
  if "%DBN%"=="" exit /b 0
  set "MESSAGE=!RES_DROP_DB:DB=%DBN%!"
  call :logger !LOG-INFO! "!MESSAGE!"
  docker exec -i "%CONT_DB%" dropdb -U "%DB_SUPER%" --if-exists "%DBN%"
  call :check_error "dropdb"
  exit /b %errorlevel%

:resolve_containers
  if not defined CONT_DB for /f "tokens=*" %%i in ('docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps "%POSTGRES%" --format "{{.Names}}"') do set "CONT_DB=%%i"
  if not defined CONT_APP for /f "tokens=*" %%i in ('docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps "%SERVER%" --format "{{.Names}}"') do set "CONT_APP=%%i"
  exit /b 0

:wait_postgres
  call :resolve_containers
  set /a "attempts=1"
  :wait_pg_loop
  <nul set /p=.
  docker exec "%CONT_DB%" pg_isready -U "%DB_SUPER%" >nul 2>&1
  if %errorlevel% equ 0 exit /b
  if %attempts% GEQ %max_attempts% (
    set "msg_cont=%proyecto% - !WORD_SERVICE! : %CONT_DB%" 
    set "MESSAGE=!RES_WAIT_DB3:PROYECTO=%msg_cont%!"
    call :logger !LOG-ERROR! "!MESSAGE!"
    exit /b 1
  )
  set /a attempts+=1
  set "MESSAGE=!RES_WAIT_DB1:COUNT=%attempts%!"
  call :logger !LOG-INFO! "!MESSAGE!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
  goto :wait_pg_loop

:cleanup_restore
  if exist "%restore_root%" rd /s /q "%restore_root%" >nul 2>&1
  exit /b 0

:require_file_size
  set "FILE=%~1"
  if not exist "%FILE%" (
    call :fail "!RES_SRC_NOT_FOUND:FILE=%FILE%!"
    exit /b 1
  )
  for %%A in ("%FILE%") do set "size=%%~zA"
  if %size% LSS 1024 (
    call :fail "!RES_FILE_EMPTY:FILE=%FILE%!"
    exit /b 1
  )
  exit /b 0

:check_error
  if %errorlevel% EQU 0 exit /b 0
  call :fail "!RES_ERR_CMD:CMD=%~1!"
  exit /b 1

:fail
  set "MESSAGE=%~1"
  set "EXIT_CODE=1"
  call :logger !LOG-ERROR! "!MESSAGE!"
  call :cleanup_restore
  exit /b 1

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2"
  exit /b

:exit
  :: Devolvemos el control al menu
  endlocal
  exit /b %EXIT_CODE%
