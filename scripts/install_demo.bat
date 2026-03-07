@echo off
:: ===============================================================================
:: PROGRAM:   install.demo.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    [Telepieza - Mariano Vallespín]
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      01/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Install trytond tryton 
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: Analiza si la llamada es del tcd.bat
set "proyecto=%~1"
set "ins_demo_action=%~2"
set "log_action=!LOG-INFO!"
set /a "wait_timedem=10"
set "confirm="

call "%DIR_SCRIPT%install_header.bat" "%proyecto%" "%ins_demo_action%" "%DEMO%" "install_demo"
if %ERRORLEVEL% NEQ 0 goto :exit
:: Si es de install.bat seguimos en el proceso de instalacion
if /i "%ins_demo_action%"=="%INS%" goto :run_install_modules_demo

:menu_trytond_demo
  cls
  set "option="
  set "confirm="
  set "MESSAGE="
  :: Banner
  call "%DIR_SCRIPT%banner.bat" %TRYTON%
  echo ===============================================================================
  call :logger %MENU% "!INSTALL_MODU_DE!" "10"
  echo ===============================================================================
  call :logger "%MENU%" "1. !INSTALL_MODU_01!" "5"
  call :logger "%MENU%" "2. !INSTALL_MODU_02!" "5"
  call :logger "%MENU%" "3. !INSTALL_MODU_03!" "5"
  call :logger "%MENU%" "4. !INSTALL_MODU_10:VERSION=%CURRENT_VERSION%!" "5"
  call :logger "%MENU%" "5. !INSTALL_MODU_11!" "5"
  call :logger "%MENU%" "6. !INSTALL_MODU_12!" "5"
  call :logger "%MENU%" "7. !INSTALL_MODU_14!" "5"
  call :logger "%MENU%" "8. !INSTALL_MODU_15!" "5"
  call :logger "%MENU%" "Q. !INSTALL_MODU_19!" "5"
  echo ========================================================
  echo.
  set /p "option=%BS%        !C_M_YELLOW!%SELECT_OPT%!C_M_RESET! "
  if "%option%"=="1" goto :check_database_demo
  if "%option%"=="2" goto :check_rules_demo
  if "%option%"=="3" goto :check_extensions_demo
  if "%option%"=="4" goto :run_modules_demo
  if "%option%"=="5" goto :database_postgres_demo 
  if "%option%"=="6" goto :logs_demo 
  if "%option%"=="7" goto :compare_menu_modules_demo
  if "%option%"=="8" goto :listing_menu_modules_demo
  if /i "%option%"=="q" goto :exit

  set "MESSAGE=%option% %LOG_ERR_OPT%"
  call :logger "%LOG-WARN%" "%MESSAGE%"
  pause & goto :menu_trytond_demo

:: 01
:check_database_demo
  set "command=\l"
  call :run_trytond_demo "%POSTGRES%" "!command!" "%file_table%" "%file_err%"
  if %ERRORLEVEL%==0 (
    call "%DIR_SCRIPT%install_reports.bat" "%TRYTON%" "1" "L" "!INSTALL_MODU_01!" "0" "%file_table%" "%DEMO%"
  )
  if /i "%ins_demo_action%"=="%INS%" exit /b
  pause & goto :menu_trytond_demo
:: 02
:check_rules_demo
  set "command=\du"
  call :run_trytond_demo "%POSTGRES%" "!command!" "%file_table%" "%file_err%"
  if %ERRORLEVEL%==0 (
    call "%DIR_SCRIPT%install_reports.bat" "%TRYTON%" "1" "U" "!INSTALL_MODU_02!" "0" "%file_table%" "%DEMO%"
  )
  if /i "%ins_demo_action%"=="%INS%" exit /b
  pause & goto :menu_trytond_demo
:: 03
:check_extensions_demo
  set "command=\dx"
  call :run_trytond_demo "%POSTGRES%" "!command!" "%file_table%" "%file_err%"
  if %ERRORLEVEL%==0 (
    call "%DIR_SCRIPT%install_reports.bat" "%TRYTON%" "1" "X" "!INSTALL_MODU_03!" "0" "%file_table%" "%DEMO%"
  )
  if /i "%ins_demo_action%"=="%INS%" exit /b
  pause & goto :menu_trytond_demo

:: Proceso install.
:run_install_modules_demo
  set "cmd=SELECT 1 FROM pg_catalog.pg_database WHERE datname='!DB_NAME_DEMO!';"
  call :run_trytond_demo "%POSTGRES%" "!cmd!" "%file_log%" "%file_err%"
  if %ERRORLEVEL% EQU 0 (
    call :check_database_demo
    call :check_rules_demo
    call :check_extensions_demo
  )
  call :run_modules_demo
  call :logs_demo
  exit /b

:: 04
:run_modules_demo

:: Visualizar datos cabecera
:: 2. Construir el nombre del fichero y la URL
if /i not "!TRYTON_FILE_DEMO!"=="" set "TRYFILENAME=!TRYTON_FILE_DEMO!"
if /i "!TRYTON_FILE_DEMO!"=="" set "TRYFILENAME=database-"
if /i not "!TRYTON_DATA_DEMO!"=="" set "BASE_URL=!TRYTON_DATA_DEMO!"
if /i "!TRYTON_DATA_DEMO!"=="" set "BASE_URL=https://www.tryton.org/~demo/"
set "FILENAME=!TRYFILENAME!!CURRENT_VERSION!.dump"
set "FULL_URL=!BASE_URL!!FILENAME!"
set "FULL_FILE=!DIR_SQL!\!FILENAME!"
set "FULL_DUMP=https://www.tryton.org/~demo/database-!CURRENT_VERSION!.dump"

call :head_modules_demo

:: Solicita confirmación por parte del usuario
set "MESSAGE=!INSTALL_MODU_EMPTY:PROYECTO=%DB_NAME_DEMO%!"
set /p "confirm=%BS%        !C_M_GREEN!!MESSAGE!!C_M_RESET! "
if /i not "%confirm%"=="YES" (
   echo.
   call :logger "!LOG-CANCEL!" "!LOG_INSTALL_CANCEL!"
   call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "5" "1" "N"
   goto :menu_trytond_demo
)

:: del 1 al 6
call :database_process_demo "YES" "%INS%"
:: 7 curl
call :logger "!INS!" "[7.-] !INSTALL_MODU_HEAD24! !FULL_URL!" 
if exist "!FULL_FILE!" (
 set "MESSAGE=!INSTALL_MODU_HEAD30:PROYECTO=%FILENAME%!"
 call :logger "%INS%" "!MESSAGE! !DIR_SQL!" "3"
) else (
   curl -o !FULL_FILE! -L !FULL_URL!
   if exist "!FULL_FILE!" (
    set "MESSAGE=!INSTALL_MODU_HEAD31:PROYECTO=%FILENAME%!"
    call :logger "%INS%" "!MESSAGE! !DIR_SQL!" "3"
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timedem!" "1"
   )     
)
:: 8. Inyección en la base de datos (Ejemplo: db tryton)
call :logger "%INS%" "[+] !INSTALL_MODU_HEAD32! !DB_NAME_DEMO!" "3"
type !FULL_FILE! | docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U "%POSTGRES%" -d "%DB_NAME_DEMO%"
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timedem!"  

call :logger "!INS!" "[8.-] !INSTALL_MODU_HEAD25!" 
set  "cmd=UPDATE ir_module SET state = 'not activated' WHERE name = 'authentication_none';"
call :run_trytond_demo "%POSTGRES%" "!cmd!" "%file_base%"

call :logger "%INS%" "[9.-] !INSTALL_MODU_HEAD34!" "3"
set "COM1=TRYTOND_DATABASE_URI=!DB_URI! trytond-admin -c /etc/trytond.conf -d %DB_NAME_DEMO%" 
set "COM3= --email !EMAIL! -vv"
set "cmd=TRYTONPASSFILE=/tmp/.passwd !COM1! --update-modules-list !COM3!"
call :run_trytond_demo "%SERVER%" "!cmd!" "" "%file_base%" "YES"

call :logger "%INS%" "[10.-] !INSTALL_MODU_HEAD18!" "3" 
: Reports Verificar y comprobar que todos los módulos están activated
call :compare_modules_install_demo "%MENU%" "!INSTALL_MODU_HEAD18!" "3"
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timedem!"  
:: Reports Listar todos los modulos 
call :logger "%INS%" "[11.-] !INSTALL_MODU_HEAD19!" "3"
call :listing_modules_demo "%MENU%" "!INSTALL_MODU_HEAD19!" "3"
call :logger "!LOG-SUCC!" "!INSTALL_MODU_END!" "3"
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timedem!" "1" 
if /i "%ins_demo_action%"=="%INS%"  exit /b
echo.
pause & goto :menu_trytond_demo

:: 05
:database_postgres_demo
   echo.
   set "confirm="
   set "MESSAGE=!INSTALL_MODU_DELCRE:PROYECTO=%DB_NAME_DEMO%!"
   set /p "confirm=%BS%        !C_M_GREEN!!MESSAGE!!C_M_RESET! "
   if /i not "%confirm%"=="YES" (
     call :logger "!LOG-CANCEL!" "!LOG_INSTALL_CANCEL!"
     call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "5" "1" "N"
     goto :menu_trytond_demo
   )
   echo.
   set "confirm="
   set "MESSAGE=!INSTALL_MODU_BACKUP:PROYECTO=%DB_NAME_DEMO%!"
   set /p "confirm=%BS%        !C_M_GREEN!!MESSAGE!!C_M_RESET! "
   call :database_process_demo "%confirm%" "%APP%"
   call :logger "!LOG-SUCC!" "!INSTALL_MODU_END!"
   call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "5" "1" "N"
   goto :menu_trytond_demo
   
:database_process_demo   
   set "confirm=%~1"
   set "process=%~2"
   echo.
   :: 1.- Parar el servicio de postgres para desactivar posibles conexiones de usuarios
   call :logger "%INS%" "[1.-] !INSTALL_MODU_HEAD11! - stop %POSTGRES%" "3"
   :: docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps --status running -q | findstr "^" >nul 2>&1
   docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps "%POSTGRES%" | findstr /I "Up" >nul
   if %ERRORLEVEL% EQU 0 (
     docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" stop "%POSTGRES%" >nul 2>&1
     call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timedem!"  
   )  
   :: 2.- Activar el servicio de postgres
   call :logger "%INS%" "[2.-] !INSTALL_MODU_HEAD12! - start %POSTGRES%" "3"
   docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" start "%POSTGRES%" >nul 2>&1 
   call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timedem!"  
   if /i "%ins_demo_action%" NEQ "%INS%" if /i "%confirm%"=="YES" (
     :: 3.- Realizar una copia de seguridad de la base de datos
     call :logger "%INS%" "[3.-] !INSTALL_MODU_HEAD13!" "3"
     call "%DIR_SCRIPT%backup.bat" "%TRYTON%" "%process%"
     call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timedem!"  
   )
   :: 4.- Eliminar la base de datos %DB_NAME_DEMO% si existe
   call :logger "%INS%" "[4.-] !INSTALL_MODU_HEAD14! %DB_NAME_DEMO%" "3"
   docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" dropdb -U postgres --if-exists "%DB_NAME_DEMO%"
   call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timedem!"  
   :: 5.- Crear la base de datos %DB_NAME_DEMO% 
   call :logger "%INS%" "[5.-] !INSTALL_MODU_HEAD15! %DB_NAME_DEMO%" "3"
   docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" createdb -U postgres "%DB_NAME_DEMO%"
   call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timedem!"  
   :: 6.- Probando conexión a la base de datos
   call :logger "%INS%" "[6.-] !INSTALL_MODU_HEAD16! %DB_NAME_DEMO%" "3"
   set  "cmd=SELECT current_database();"
   call :run_trytond_demo "%POSTGRES%" "!cmd!"
   exit /b

:: 06
:logs_demo
 if /i "%ins_demo_action%"=="%INS%" (
    call :logger "%INS%" "!INSTALL_MODU_12! %DB_NAME%" "3"
  ) else (
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "fill_in_field" "%TXT%" "7.- !INSTALL_MODU_12!" "3"
  )
  call "%DIR_SCRIPT%logger.bat" "%TRYTON%" "%SQL%"
  if /i "%ins_demo_action%"=="%INS%" exit /b
  pause & goto :menu_trytond_demo

::07
:compare_menu_modules_demo
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "fill_in_field" "%TXT%" "7.- !INSTALL_MODU_14!" "3"
  call :compare_modules_install_demo "%APP%" "!INSTALL_MODU_14!" "3"
  pause & goto :menu_trytond_demo

:: 08
:listing_menu_modules_demo
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "fill_in_field" "%TXT%" "8.- !INSTALL_MODU_15!" "3"
  call :listing_modules_demo "%APP%" "!INSTALL_MODU_15!" "3"
  pause & goto :menu_trytond_demo

:: 08 04-01
:listing_modules_demo
  set "event=%~1"
  set "title=%~2"
  set "numer=%~3"
  set "cmd=SELECT name, state FROM ir_module ORDER BY name;"
  call :run_trytond_demo "%POSTGRES%" "!cmd!" "%file_modules%" "%file_err%"
  if %ERRORLEVEL% NEQ 0 exit /b
  call "%DIR_SCRIPT%install_reports.bat" "%proyecto%" "8" "%event%" "%title%" "%numer%" "%file_modules%" "%DEMO%"
  exit /b
  
:: 04-02
:compare_modules_install_demo
  set "event=%~1"
  set "title=%~2"
  set "numer=%~3"
  set  "cmd=SELECT name FROM ir_module WHERE state='activated' ORDER BY name;"
  call :run_trytond_demo "%POSTGRES%" "!cmd!" "%file_activ%" "%file_err%"
  if %ERRORLEVEL% NEQ 0  exit /b
  call "%DIR_SCRIPT%install_reports.bat" "%proyecto%" "6" "%event%" "%title%" "%numer%" "%file_activ%" "%DEMO%"
  exit /b

 :run_trytond_demo
   REM %1 = Servicio server o postgres
   REM %2 = comando completo a ejecutar (trytond-admin o psql SQL)
   REM %3 = logfile stdout (opcional)
   REM %4 = errfile stderr (opcional)
   REM %5 = YES (añadir en vez de sobrescribir)
   set "servicio=%~1"
   set "cmd=%~2"
   set "logfile=%~3"
   set "errfile=%~4"
   set "add=%~5"
   REM --- Limpiar ficheros si no se añade
   if not "%logfile%"=="" if /i not "%add%"=="YES" if exist "%logfile%" del "%logfile%" >nul
   if not "%errfile%"=="" if /i not "%add%"=="YES" if exist "%errfile%" del "%errfile%" >nul

   REM --- Construcción de redirecciones de Windows
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
  if /i "%servicio%"=="%SERVER%" (
    ::Para SERVER, ejecutamos bash -c "<cmd>" y luego ponemos la redirección de Windows
    docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%SERVER%" bash -c "%cmd%" %redir_out% %redir_err%
  )
  if /i "%servicio%"=="%POSTGRES%" (
    REM Para POSTGRES, usamos psql directamente
    docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U postgres -d "!DB_NAME_DEMO!" -At -c "%cmd%" %redir_out% %redir_err%
  )
  set "status=%ERRORLEVEL%"
  :: --- Esperar si OK ---
  if %status% EQU 0 (
    if /i "%ins_demo_action%" EQU "%INS%" (
        call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timedem!" "1"
    )
    exit /b 0
  )
  if %status% NEQ 0 (
     if exist "%errfile%" if not "%errfile%"=="" (
       call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "display_file_event_all" "!LOG-ERROR!" "%errfile%"
       exit /b %status%
     )
     if exist "%logfile%" if not "%logfile%"=="" (
      call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "display_file_event_all" "!LOG-INFO!" "%logfile%"
      exit /b %status%
     )
  )
  exit /b 0

:head_modules_demo
  echo.
  echo    ===================================================================
    call :logger "%MENU%" "!INSTALL_MODU_HEAD01! %DB_NAME_DEMO%" "8"
  echo    ===================================================================
  echo.
    call :logger "%MENU%" "!INSTALL_MODU_HEAD02! %DB_NAME_DEMO%" "8"
  echo         --------------------------------------------------
  echo.
    call :logger "%MENU%" "!INSTALL_MODU_HEAD04! %proyecto%" "3"
    call :logger "%MENU%" "!INSTALL_MODU_HEAD07! [!CURRENT_VER_MENU!]" "3"
    call :logger "%MENU%" "!INSTALL_MODU_HEAD05! %DB_NAME_DEMO%" "3"
    call :logger "%MENU%" "!INSTALL_MODU_HEAD08! [!CURRENT_PG_VERSION!]" "3"   
    call :logger "%MENU%" "!INSTALL_MODU_HEAD06! %DB_URI%" "3"
    call :logger "%MENU%" "!INSTALL_MODU_HEAD03! %DIR_HOME%%COMPOSE_FILE%" "3"
  echo.
  echo    ======================================================================================
    call :logger "%MENU%" "!INSTALL_MODU_HEAD10! %DB_NAME_DEMO%"  "8"
  echo    ======================================================================================
  echo.
    call :logger "%MENU%" "[+] 1.-!INSTALL_MODU_HEAD11!" "3"  
    call :logger "%MENU%" "[+] 2.-!INSTALL_MODU_HEAD12!" "3"
    call :logger "%MENU%" "[+] 3.-!INSTALL_MODU_HEAD13! !INSTALL_MODU_HEAD35!" "3"
    call :logger "%MENU%" "[+] 4.-!INSTALL_MODU_HEAD14! %DB_NAME_DEMO%" "3"
    call :logger "%MENU%" "[+] 5.-!INSTALL_MODU_HEAD15! %DB_NAME_DEMO%" "3"
    call :logger "%MENU%" "[+] 6.-!INSTALL_MODU_HEAD16! %DB_NAME_DEMO%" "3"
    call :logger "%MENU%" "[+] 7.-!INSTALL_MODU_HEAD24:VERSION=%CURRENT_VERSION%! %DB_NAME_DEMO%" "3"
    call :logger "%MENU%" "[+] 8.-!INSTALL_MODU_HEAD25!" "3"
  echo.
    call :logger "%MENU%" "[+] 9.-!INSTALL_MODU_HEAD23:VERSION=%CURRENT_VERSION%!" "3"
    call :logger "%MENU%" "9.1-!INSTALL_MODU_DEMOC1! ( !D1: =, ! )" "8"
    call :logger "%MENU%" "9.2-!INSTALL_MODU_DEMOC2! ( !D2: =, ! )" "8"
    call :logger "%MENU%" "9.3-!INSTALL_MODU_DEMOC3! ( !D3: =, ! )" "8"
    call :logger "%MENU%" "9.4-!INSTALL_MODU_DEMOC4! ( !D4: =, ! )" "8"
    call :logger "%MENU%" "9.5-!INSTALL_MODU_DEMOC5! ( !D5: =, ! )" "8"
    call :logger "%MENU%" "9.6-!INSTALL_MODU_DEMOC6! ( !D6: =, ! )" "8"
  echo.
    call :logger "%MENU%" "[+] 10.-!INSTALL_MODU_HEAD18!" "3"
    call :logger "%MENU%" "[+] 11.-!INSTALL_MODU_HEAD19!" "3"
  echo.
    call :logger "%MENU%" "[+] 12.-!INSTALL_MODU_HEAD26!" "3"
    call :logger "%MENU%" "12.1-!INSTALL_MODU_HEAD27!" "8"
  echo.
exit /b

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:exit
  endlocal
  exit /b 0
