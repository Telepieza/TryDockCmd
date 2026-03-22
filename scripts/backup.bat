@echo off
:: ===============================================================================
:: PROGRAM:   backup.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      23/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Database Hot-Export - Exportar imágenes y Base de datos (BACKUP)
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: Analiza si la llamada es del tcd.bat
set "proyecto=%~1"
set "back_action=%~2"
set "contdown=0"
set /a "wait_timeback=10"
set "TIME_BK=%date:~-4%-%date:~3,2%-%date:~0,2%_%time:~0,2%-%time:~3,2%"
set "FILE_BK=%TRYTON%_%TIME_BK: =0%"
set "destino=%DIR_BACKUP%\%FILE_BK%"
set "file_err=%DIR_TMP%\trytond_backup_err.txt"
set "file_tmp=%DIR_TMP%\trytond_backup_tmp.txt"
set "DB_ERRDE=0"
set "log_action=!LOG-INFO!"
call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call :logger "%APP%" "backup %back_action%"
set "file_zip=%DIR_BACKUP%\%FILE_BK%.zip"
 
if /i "%back_action%"=="%INS%"  (
  set "log_action=%INS%"
  goto :continue
)
:: mensajes visualizados en consola
set "value_title=!BCK_PROCESS:PROYECTO=%MENU_TRYDOCK%! %TRYTON%:[%CURRENT_VER_MENU%] - [%CURRENT_PG_VERSION%]"
call :logger "%MENU%" "[+] 1.- !value_title!" "3"
set "MESSAGE=!BCK_DEST:PROYECTO=%destino%!"
call :logger "%MENU%" "[+] 2.- !MESSAGE!" "3"
set "MESSAGE=!BCK_CHECK:PROYECTO=%proyecto%!"
call :logger "%MENU%" "[+] 3.- !MESSAGE!" "3"
call "%DIR_SCRIPT%status.bat" "%proyecto%" "%SQL%"

:: contenedores activos con errorlevel=0
if %errorlevel% equ 0 goto :continue

:: Contenedores parados o la DDBB no acepta conexiones.
set "contdown=1"  
set "MESSAGE=!BCK_CONT_STOP:PROYECTO=%POSTGRES%!"
call :logger "%MENU%" "3.1.- !MESSAGE!" "8"
set "MESSAGE=!BCK_STARTING:PROYECTO=%POSTGRES%!"
call :logger "%MENU%" "3.2.- !MESSAGE!" "8"
:: Nos aseguramos que los contenedores están activos
call "%DIR_SCRIPT%startup.bat" %proyecto% "%SQL%"
if %errorlevel% EQU 4 (
  set "MESSAGE=!BCK_CONT_STOP:PROYECTO=%POSTGRES%!"
  call :logger "!LOG-ERROR!" "!MESSAGE!"
  goto :exit
)

:continue
if /i "%SERVER_IMAGE%"=="" ( 
    set "SERVER_IMAGE=%TRYTON_TRYTON%:%TRYTON_VERSION%"
    call :logger "%CHECK%" "%LOG_INFO_SERVER% %TRYTON% %SERVER_IMAGE%"
)

if /i "%POSTGRES_IMAGE%"=="" (
    set "POSTGRES_IMAGE=%POSTGRES%:%POSTGRES_VERSION%"
    call :logger "%CHECK%" "%LOG_INFO_POSTGRES% %TRYTON% %POSTGRES_IMAGE%"
)  

if /i "%CURRENT_POSTGRES%"=="" set "CURRENT_POSTGRES=%TRYTON_POSTGRES%-1"
if /i "%CURRENT_TRYTON%"=="" set "CURRENT_TRYTON=%TRYTON%-%SERVER%-1"
if /i "%CURRENT_VER_MENU%"=="" set "CURRENT_VER_MENU=%TRYTON-VERSION%"
if /i "%CURRENT_PG_VERSION%"=="" set "CURRENT_PG_VERSION=%POSTGRES-VERSION%"
if "!DB_NAME!"=="" set "DB_NAME=%TRYTON%"
if /i "!TRYTON_DB_DEMO!"=="" set "TRYTON_DB_DEMO=%DB_NAME_DEMO%"
if /i "%DB_NAME_DEMO%" NEQ "%TRYTON_DB_DEMO%" set "DB_NAME_DEMO=%TRYTON_DB_DEMO%"

:: Busca DDBB tryton 
call :check_database "!DB_NAME!" "4"
if "%DB_ERROR%"=="2" goto :exit

if /i "%back_action%"=="%INS%"  goto :data_backup

:: Busca DDBB tryton_demo
call :check_database "!DB_NAME_DEMO!" "5"
if "%DB_ERROR%"=="2" (
  set "DB_ERROR=0"
  set "DB_ERRDE=1"
  set "MESSAGE=!BCK_NO_DDBB:PROYECTO=%DB_NAME_DEMO%!"
  call :logger "%LOG-WARN%" "5.1.- !MESSAGE!" "8"
)

call :logger "%MENU%" "[+] 6.- !BCK_INFOR!" "3"
:: Informa el guardar los datos en un fichero .zip
set "MESSAGE=!BCK_FILE_ZIP_2:DESTINO=%destino%!"
call :logger "%MENU%" "6.1.- !MESSAGE! \%FILE_BK%.zip" "8"
:: Informa que la carpeta temporal sera eliminada
set "MESSAGE=!BCK_TEMPORARY_2:DESTINO=%destino%!"
call :logger "%MENU%" "6.2.- !MESSAGE!" "8"
:: Informa del comando pg_dumpall, aplicado para copiar las bases de datos.
set "msg_cont=docker exec !CURRENT_POSTGRES! pg_dumpall --clean -U !DB_HOSTNAME!"
set "MESSAGE=!BCK_PG_DUMPALL:DESTINO=%msg_cont%!"
call :logger "%MENU%" "6.3.- !MESSAGE!" "8"

:: Opciones del backup
:menu_backup
  echo.
  set "MESSAGE=!DB_NAME!"
  if "!DB_ERRDE!"=="0" set "MESSAGE=!MESSAGE! - !DB_NAME_DEMO!"
  set "type="
  set "MODE="
  echo     ==========================================================================
  call :logger "%MENU%" "!BCK_MENU_TITLE! - %TRYTON%:[%CURRENT_VER_MENU%] - [%CURRENT_PG_VERSION%]" "10"
  echo     ==========================================================================
  echo.
  call :logger "%MENU%" "!BCK_MENU_TITLE!" "5"
  echo.
  call :logger "%MENU%" "!BCK_OPT1!" "5"
  call :logger "%MENU%" "!BCK_OPT2!" "5"
  call :logger "%MENU%" "!BCK_OPT3:PROYECTO=%MESSAGE%!" "5"
  call :logger "%MENU%" "!BCK_OPT4:PROYECTO=%MESSAGE%!" "5"
  call :logger "%MENU%" "!BCK_OPT5:PROYECTO=%MESSAGE%!" "5"
  call :logger "%MENU%" "!BCK_OPT6!" "5"
  echo.
  set /p "type=%BS%        !C_M_YELLOW!!BCK_PROMPT!!C_M_RESET! "
  echo.
  if "%type%"=="1" goto :full_backup   
  if "%type%"=="2" goto :data_backup  
  if "%type%"=="3" set MODE=schema&& goto schema_data
  if "%type%"=="4" set MODE=data&& goto schema_data
  if "%type%"=="5" set MODE=full_db&& goto schema_data
  if "%type%"=="6" goto :end   
  call :logger "!LOG-WARN!" "!BCK_ERR_OPT!"
  goto :menu_backup
  
:full_backup 

  set "MESSAGE=!BCK_EXP_IMG_DB:DBIMAGEN=%POSTGRES_IMAGE_NAME%!"
  call :logger "!LOG-INFO!" "!MESSAGE!"
  if not exist "%destino%" mkdir "%destino%" 
  :: Docker save copiamos la imagen de Base de Datos a un fichero img_postgres.tar
  docker save "%POSTGRES_IMAGE%" > "%destino%\img_postgres.tar"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeback!" "1"
  set "MESSAGE=!BCK_EXP_IMG_TRY:TRYIMAGEN=%SERVER_IMAGE_NAME%!"
  call :logger "!LOG-INFO!" "!MESSAGE!"
  :: Docker save copiamos la imagen de tryton a un fichero img_tryton.tar
  docker save "%SERVER_IMAGE%" > "%destino%\img_tryton.tar"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeback!" "1"
:: Opcion 2 Para poder realizar los backup de los contenedores tienen que estar activos.

:data_backup
  if not exist "%destino%" mkdir "%destino%" 
  set "msg_cont=%CURRENT_POSTGRES% - !WORD_ROUTE! %proyecto%:/var/lib/trytond/db !WORD_TO! %destino%\tryton_db_data.sql" 
  set "MESSAGE=!BCK_RUN_DUMP:CONTENEDOR=%msg_cont%!"
  call :logger "!log_action!" "!MESSAGE!"
  :: Usamos el nombre del servicio definido en el YAML (tryton-postgres), utilizando el comando pg_dumpall
  if exist "%file_err%" del "%file_err%" >nul
  set "file_sql=%destino%\tryton_%DB_HOSTNAME%_dumpall.sql"
  docker exec "%CURRENT_POSTGRES%" pg_dumpall --clean -U "%DB_HOSTNAME%" >"%file_sql%" 2>"%file_err%"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeback!" "1"
  : Verificación de integridad avanzada
  if not exist "%file_sql%" (
      set "MESSAGE=!BCK_FILE_NOT_SQL:DESTINO=%file_sql%!"
      call :logger "!LOG-ERROR!" "!MESSAGE!"
      goto :exit
  )
  :: Obtener tamaño de forma segura para rutas con espacios
  for %%A in ("%file_sql%") do set "size=%%~zA"
  :: Si el tamaño es menor a 1KB, probablemente es un error de Postgres
  if !size! LSS 1024 (
      set "db_err=Unknown Postgres Error"
      set /p db_err=<%file_err%
      set "size_work=!size!"
      set "MESSAGE=!BCK_FILE_CORRUPT:SIZE=%size_work%!"
      call :logger "!LOG-ERROR!" "!MESSAGE! !db_err!"
      goto :exit
  )

  call :logger "!log_action!" "!BCK_FILE_SQL:DESTINO=%file_sql%! (!size! bytes)"

:found_data
  if not exist "%destino%" mkdir "%destino%" 
  set "msg_cont=%CURRENT_TRYTON% !WORD_ROUTE! %proyecto%:/var/lib/trytond/ !WORD_TO! %destino%"
  set "MESSAGE=!BCK_COPY_FILES:DESTINO=%msg_cont%!"
  call :logger "!log_action!" "!MESSAGE!"
  :: Copiamos la carpeta de datos del servidor a la carpeta destino.
  :: La copia de la carpeta trytond/db es muy importante, son nuestros datos creados en la base de datos.
  docker cp "%CURRENT_TRYTON%:/var/lib/trytond/" "%destino%" >nul
  if !errorlevel! NEQ 0 (
    set "MESSAGE=!BCK_COPY_ERROR:DESTINO=%msg_cont%!"
    call :logger "!LOG-ERROR!" "!MESSAGE!"
  )
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeback!" "1"
:: Copia el fichero %COMPOSE_FILE%, por seguridad. N copia el fichero .env, por tener las claves del acceso a la base de datos.
if /i "%back_action%"=="%INS%"  goto :found_file_zip

:found_compose
  set "msg_cont=!WORD_FILE!: %destino%\%COMPOSE_FILE%"
  set "MESSAGE=!BCK_SAVE_YAML:DESTINO=%msg_cont%!"
  call :logger "!log_action!" "!MESSAGE!"
  :: Realiza un copy del %COMPOSE_FILE% del proyecto donde se ejecuta el tcd.bat
  copy "%DIR_HOME%%COMPOSE_FILE%" "%destino%\%COMPOSE_FILE%" >nul
  
:found_file_zip
  set "MESSAGE=!BCK_FILE_ZIP_2:DESTINO=%destino%!"
  call :logger "!log_action!" "!MESSAGE! %FILE_BK%.zip" 
  powershell -Command "$ProgressPreference = 'SilentlyContinue'; Compress-Archive -Path '%destino%' -DestinationPath '%file_zip%' -Force"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeback!" "1"
  if not exist "%file_zip%"  tar -a -c -f "%file_zip%" -C "%destino%" . 
  :: Si el valor de la variable contdown_ es 1, parara los contenedores por ser arrancados al inicio del proceso de backup
  if "%contdown%"=="1" (
    call :logger "!log_action!" "!BCK_RESTORE_STATE!"
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeback!" "1"
    call "%DIR_SCRIPT%startdown.bat" "%proyecto%" "%CHECK%" "STOP"
  )
  set "MESSAGE=!BCK_SUCCESS:DESTINO=%destino%!"
  call :logger "!LOG-SUCC!" "!MESSAGE!"
  if not exist "%file_zip%" goto :exit
  if not exist "%destino%" goto :exit
  set "MESSAGE=!BCK_FILE_ZIP:DESTINO=%file_zip%!"
  call :logger "!LOG-SUCC!" "!MESSAGE!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeback!" "1"
  rd /s /q "%destino%" >nul 2>&1
  set "MESSAGE=!BCK_TEMPORARY:DESTINO=%destino%!"
  set "fuction=!log_action!"
  if exist "%destino%" (
    set "fuction=!LOG-WARN!"
    set "MESSAGE=!BCK_NOT_TEMPORARY:DESTINO=%destino%!"
  )
  call :logger "!fuction!" "!MESSAGE!"
  goto :exit

:schema_data
  if not exist "!destino!" mkdir "!destino!" 
  if /i "%MODE%"=="schema" (
    set "file_sql=!destino!\!DB_NAME!_!MODE!.sql"
    call :logger "!log_action!" "!BCK_DUMP_DB! %DB_NAME% - !file_sql!"
    docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" pg_dump -s -U "%DB_HOSTNAME%" !DB_NAME! > "!file_sql!" 2>"%file_err%"
    call :compress_file "!file_sql!"
    if "!DB_ERRDE!"=="0" (
      set "file_sql=!destino!\!DB_NAME_DEMO!_!MODE!.sql"
      call :logger "!log_action!" "!BCK_DUMP_DB! %DB_NAME_DEMO% - !file_sql!"
      docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" pg_dump -s -U "%DB_HOSTNAME%" -d !DB_NAME_DEMO! > "!file_sql!" 2>"%file_err%"
      call :compress_file "!file_sql!"
    )
  )
  if /i "%MODE%"=="data"  (
    set "file_sql=!destino!\!DB_NAME!_!MODE!.sql"
    call :logger "!log_action!" "!BCK_DUMP_DB! %DB_NAME% - !file_sql!"
    docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" pg_dump -a -U "%DB_HOSTNAME%" --inserts --on-conflict-do-nothing -d !DB_NAME! > "!file_sql!" 2>"%file_err%"
    call :compress_file "!file_sql!"
    if "!DB_ERRDE!"=="0" (
      set "file_sql=!destino!\!DB_NAME_DEMO!_!MODE!.sql"
      call :logger "!log_action!" "!BCK_DUMP_DB! %DB_NAME_DEMO% - !file_sql!"
      docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" pg_dump -a -U "%DB_HOSTNAME%" --inserts --on-conflict-do-nothing -d !DB_NAME_DEMO! > "!file_sql!" 2>"%file_err%"
      call :compress_file "!file_sql!"
    )
  )
  if /i "%MODE%"=="full_db" (
    set "file_sql=!destino!\!DB_NAME!_!MODE!.sql"
    call :logger "!log_action!" "!BCK_DUMP_DB! %DB_NAME% - !file_sql!"
    docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" pg_dump -Fc -U "%DB_HOSTNAME%" !DB_NAME!>"!file_sql!" 2>"!file_err!"
    call :compress_file "!file_sql!"
    if "!DB_ERRDE!"=="0" (
      set "file_sql=!destino!\!DB_NAME_DEMO!_%MODE%.sql"
      call :logger "!log_action!" "!BCK_DUMP_DB! %DB_NAME_DEMO% - !file_sql!"
      docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" pg_dump -Fc -U "%DB_HOSTNAME%" !DB_NAME_DEMO!>"!file_sql!" 2>"!file_err!"
      call :compress_file "!file_sql!"
    )
  )
  echo.
  pause
  cls
  call "%DIR_SCRIPT%banner.bat" "%TRYTON%"
  goto :menu_backup

:compress_file
  set "FILE_SQL=%~1"
  if not exist "%FILE_SQL%" (
    set "MESSAGE=!BCK_FILE_NOT_SQL:DESTINO=%FILE_SQL%!"
    call :logger "!LOG-ERROR!" "!MESSAGE!"
    exit /b
  )
  set "FILE_ZIP=%~dpn1.zip"
  set "MESSAGE=!BCK_FILE_ZIP_3:DESTINO=%destino%!"
  call :logger "!log_action!" "!MESSAGE! \%FILE_ZIP%"
  powershell -Command "$ProgressPreference = 'SilentlyContinue'; Compress-Archive -Path '%FILE_SQL%' -DestinationPath '%FILE_ZIP%' -Force"
  if not exist "%FILE_ZIP%" (
    set "MESSAGE=!BACK_FILE_EMPTY:FILE=%FILE_ZIP%!"
    call :logger "!LOG-ERROR!" "!MESSAGE!"
    exit /b
  )
  
  for %%A in ("%FILE_ZIP%") do set "size=%%~zA"
  :: Si el tamaño es menor a 1KB, probablemente es un error de Postgres
  if !size! LSS 1024 (
      set "db_err=Zip file empty %FILE_ZIP%"
      set "size_work=!size!"
      set "MESSAGE=!BCK_FILE_CORRUPT:SIZE=%size_work%!"
      call :logger "!LOG-ERROR!" "!MESSAGE! !db_err!"
      exit /b
  )
  del "%FILE_SQL%" >nul 2>&1
  set "MESSAGE=!BCK_FILE_ZIP:DESTINO=%FILE_ZIP%!"
  call :logger "!LOG-SUCC!" "!MESSAGE!"
  exit /b

:check_database
  set "database=%~1"
  set "numer=%~2"
  if exist "%file_tmp%" del "%file_tmp%" >nul
  set "DB_ERROR=0"
  set "DB_TRY=0"
  set "DB_TDE=0"
  set "DB_EXISTS="
  set "MESSAGE=!BCK_LOCALE:PROYECTO=%database%!"
  call :logger "%MENU%" "[+] !numer!.- !MESSAGE!" "3"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U "%POSTGRES%" -d "%database%" -tA -c "SELECT 1 FROM pg_catalog.pg_database WHERE datname='%database%';" >"%file_tmp%" 2>&1
:: Comprobar errorlevel inmediatamente
if %ERRORLEVEL% NEQ 0 (
    set "DB_ERROR=2"
    if /i "!DB_NAME_DEMO!" NEQ "!database!" (
       call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "display_file_event_all" "!LOG-ERROR!" "%file_tmp%"
    )
    exit /b
)
:: Si llegamos aqui, el comando devolvio 0 - OK
for /f "usebackq tokens=*" %%D in ("%file_tmp%") do set "DB_EXISTS=%%D"
if "%DB_EXISTS%"=="1" (
  set "DB_ERROR=0"
  set "MESSAGE=!BCK_DDBB:PROYECTO=%database%!"
  call :logger "%MENU%" "!numer!.1.- !MESSAGE!" "8"
)
if "%DB_EXISTS%" NEQ "1" (
  set "DB_ERROR=1"
  set "MESSAGE=!BCK_NO_DDBB:PROYECTO=%database%!"
  call :logger "%MENU%" "!numer!.1.- !MESSAGE!" "8"
)
exit /b

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:end
  endlocal
  exit /b 2

:exit
  if /i "%back_action%" NEQ "%INS%" call :logger "!LOG-SUCC!" "!BCK_ENDING!"
  endlocal
  exit /b 0
