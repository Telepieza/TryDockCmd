@echo off
:: ===============================================================================
:: PROGRAM:   install.tryton.bat
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
set "ins_tryton_action=%~2"
set "log_action=!LOG-INFO!"
set /a "wait_timetry=10"
set /a "wait_timetry5=5"
set /a "wait_timetry20=20"

call "%DIR_SCRIPT%install_header.bat" "%proyecto%" "%ins_tryton_action%" "%INS%" "install_tryton"
if %ERRORLEVEL% NEQ 0 goto :exit

:: Si es de install.bat seguimos en el proceso de instalacion
if /i "%ins_tryton_action%"=="%INS%" (
  call :check_database
  call :check_rules
  call :check_extensions
  call :run_modules
  call :logs
  goto :exit
)

:menu_trytond
  cls
  set "option="
  set "confirm="
  set "MESSAGE="
  :: Banner
  call "%DIR_SCRIPT%banner.bat" %TRYTON%
  echo ===============================================================================
  call :logger %MENU% "!INSTALL_MODU_RE!" "10"
  echo ===============================================================================
  call :logger "%MENU%" "1. !INSTALL_MODU_01!" "5"
  call :logger "%MENU%" "2. !INSTALL_MODU_02!" "5"
  call :logger "%MENU%" "3. !INSTALL_MODU_03!" "5"
  call :logger "%MENU%" "4. !INSTALL_MODU_20!" "5"
  call :logger "%MENU%" "5. !INSTALL_MODU_21!" "5"
  call :logger "%MENU%" "6. !INSTALL_MODU_22!" "5"
  call :logger "%MENU%" "7. !INSTALL_MODU_23!" "5"
  call :logger "%MENU%" "8. !INSTALL_MODU_24!" "5"
  call :logger "%MENU%" "9. !INSTALL_MODU_25!" "5"
  call :logger "%MENU%" "Q. !INSTALL_MODU_29!" "5"
  echo ========================================================
  echo.
  set /p "option=%BS%        !C_M_YELLOW!%SELECT_OPT%!C_M_RESET! "
  if "%option%"=="1" goto :check_database
  if "%option%"=="2" goto :check_rules
  if "%option%"=="3" goto :check_extensions
  if "%option%"=="4" goto :run_modules
  if "%option%"=="5" goto :run_languages
  if "%option%"=="6" goto :database_postgres 
  if "%option%"=="7" goto :logs 
  if "%option%"=="8" goto :compare_menu_modules
  if "%option%"=="9" goto :listing_menu_modules
  if /i "%option%"=="q" goto :exit

  set "MESSAGE=%option% %LOG_ERR_OPT%"
  call :logger "%LOG-WARN%" "%MESSAGE%"
  pause & goto :menu_trytond

:: 01
:check_database
  set "command=\l"
  call :run_trytond "%POSTGRES%" "!command!" "%file_table%" "%file_err%"
  if %ERRORLEVEL%==0 (
    call "%DIR_SCRIPT%install_reports.bat" "%TRYTON%" "1" "L" "!INSTALL_MODU_01!" "0" "%file_table%" 
  )
  if /i "%ins_tryton_action%"=="%INS%" exit /b
  pause & goto :menu_trytond
:: 02
:check_rules
  set "command=\du"
  call :run_trytond "%POSTGRES%" "!command!" "%file_table%" "%file_err%"
  if %ERRORLEVEL%==0 (
    call "%DIR_SCRIPT%install_reports.bat" "%TRYTON%" "1" "U" "!INSTALL_MODU_02!" "0" "%file_table%" 
  )
  if /i "%ins_tryton_action%"=="%INS%" exit /b
  pause & goto :menu_trytond
:: 03
:check_extensions
  set "command=\dx"
  call :run_trytond "%POSTGRES%" "!command!" "%file_table%" "%file_err%"
  if %ERRORLEVEL%==0 (
   call "%DIR_SCRIPT%install_reports.bat" "%TRYTON%" "1" "X" "!INSTALL_MODU_03!" "0" "%file_table%" 
  )
  if /i "%ins_tryton_action%"=="%INS%" exit /b
  pause & goto :menu_trytond

:: 04
:run_modules
:: Visualizar datos cabecera
call :head_modules
if /i "%ins_tryton_action%" EQU "%INS%" call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "%wait_timetry20%" "1" 
:: Solicita confirmación por parte del usuario
if /i "%ins_tryton_action%" NEQ "%INS%" (
  set "MESSAGE=!INSTALL_MODU_EMPTY:PROYECTO=%DB_NAME%!"
  set /p "confirm=%BS%        !C_M_GREEN!!MESSAGE!!C_M_RESET! "
  if /i not "%confirm%"=="YES" (
     echo.
     call :logger "!LOG-CANCEL!" "!LOG_INSTALL_CANCEL!"
     call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "%wait_timetry5%" "1" "N"
     goto :menu_trytond 
  )
)

:: del 1 al 6
call :database_process "YES" "%INS%"
:: 7.- Instalar modulos
echo.
call :logger "%INS%" "[7.-] !INSTALL_MODU_HEAD17!" "3"
set "COM1=TRYTOND_DATABASE_URI=!DB_URI! trytond-admin -c /etc/trytond.conf -d %DB_NAME%" 
set "COM2=TRYTONPASSFILE=/tmp/.passwd"
set "COM3= --email !EMAIL! -vv"

:: 1. BASE TOTAL
call :logger "%INS%" "%F1%" "4"
set "cmd=!COM2! !COM1! -u !C1! --activate-dependencies !COM3!"
call :run_trytond "%SERVER%" "!cmd!" "" "%file_base%"
:: 2. PRODUCTO Y STOCK BASE 
call :logger "%INS%" "%F2%" "4"
set "cmd=!COM2! !COM1! -u !C2! --activate-dependencies !COM3!"
call :run_trytond "%SERVER%" "!cmd!" "" "%file_base%" "YES"
:: 3. CONTABILIDAD BASE Y FACTURACION 
call :logger "%INS%" "%F3%" "4"
set "cmd=!COM2! !COM1! -u !C3! --activate-dependencies !COM3!" 
call :run_trytond "%SERVER%" "!cmd!" "" "%file_base%" "YES"
:: 4. MOTORES COMERCIALES
call :logger "%INS%" "%F4%" "4"
set "cmd=!COM2! !COM1! -u !C4! --activate-dependencies !COM3!"
call :run_trytond "%SERVER%" "!cmd!" "" "%file_base%" "YES"
:: 5. ABASTECIMIENTO
call :logger "%INS%" "%F5%" "4"
set "cmd=!COM2! !COM1! -u !C5! --activate-dependencies !COM3!"
call :run_trytond "%SERVER%" "!cmd!" "" "%file_base%" "YES"
:: 6. EXTENSIONES DE PRODUCTO
call :logger "%INS%" "%F6%" "4"
set "cmd=!COM2! !COM1! -u !C6! --activate-dependencies !COM3!"
call :run_trytond "%SERVER%" "!cmd!" "" "%file_base%" "YES"
:: 7. OPERACIONES AVANZADAS
call :logger "%INS%" "%F7%" "4"
set "cmd=!COM2! !COM1! -u !C7! --activate-dependencies !COM3!"
call :run_trytond "%SERVER%" "!cmd!" "" "%file_base%" "YES"
:: 8. VISUAL
call :logger "%INS%" "%F8%" "4"
set "cmd=!COM2! !COM1! -u !C8! --activate-dependencies !COM3!"
call :run_trytond "%SERVER%" "!cmd!" "" "%file_base%" "YES"
:: 7.1. UPDATE modules-list install language
if /i "!TRYTON_LANGUAGE!" NEQ "" (
  call :logger "%INS%" "[7.1.-] !INSTALL_MODU_HEAD34!" "3"
  set "cmd=!COM2! !COM1! --update-modules-list !COM3!"
  call :run_trytond "%SERVER%" "!cmd!" "" "%file_base%" "YES"
  call :logger "%INS%" "[8.-] !LS!" "4"
  call "%DIR_SCRIPT%install_language.bat" "%proyecto%" "%INS%"
)

:: actualizar la lista de modulos
call :logger "%INS%" "[9.-] !INSTALL_MODU_HEAD34!" "3"
set "cmd=!COM2! !COM1! --update-modules-list !COM3!"
call :run_trytond "%SERVER%" "!cmd!" "" "%file_base%" "YES"

:: Crear Emprea, Ejercicio fiscal. secuencias y periodos contables
call :logger "%INS%" "[10.-] !INSTALL_MODU_HEAD44!" "3"
call "%DIR_SCRIPT%install_accounts.bat" "%proyecto%" "%INS%"
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timetry!" "1"

:: Reports Verificar y comprobar que todos los módulos están activated
call :logger "%INS%" "[11.-] !INSTALL_MODU_HEAD18!" "3"
call :compare_modules_install "%INS%" "!INSTALL_MODU_HEAD18!" "3"
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timetry!" "1"

:: Reports Listar todos los modulos 
call :logger "%INS%" "[12.-] !INSTALL_MODU_HEAD19!" "3"
call :listing_modules "%INS%" "!INSTALL_MODU_HEAD19!" "3"
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timetry!" "1"

call :logger "%INS%" "[13.-] !INSTALL_MODU_HEAD20!" "3"
call :extract_xml_from_log "%file_base%" "%file_xml%"

if /i "%ins_tryton_action%"=="%INS%" (
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timetry!" "1" 
  exit /b
)

call :logger "!LOG-SUCC!" "!INSTALL_MODU_END!" "3"
echo.
pause & goto :menu_trytond

:run_languages
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "fill_in_field" "%TXT%" "5. !INSTALL_MODU_21!" "3"
  call "%DIR_SCRIPT%install_language.bat" "%proyecto%" "%APP%"
  goto :menu_trytond

:: 05
:database_postgres
   echo.
   set "confirm="
   set "MESSAGE=!INSTALL_MODU_DELCRE:PROYECTO=%DB_NAME%!"
   set /p "confirm=%BS%        !C_M_GREEN!!MESSAGE!!C_M_RESET! "
   if /i not "%confirm%"=="YES" (
     echo.
     call :logger "!LOG-CANCEL!" "!LOG_INSTALL_CANCEL!"
     call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "%wait_timetry5%" "1" "N"
     goto :menu_trytond 
   )
   echo.
   set "confirm="
   set "MESSAGE=!INSTALL_MODU_BACKUP:PROYECTO=%DB_NAME%!"
   set /p "confirm=%BS%        !C_M_GREEN!!MESSAGE!!C_M_RESET! "
   call :database_process "%confirm%" "%APP%"
   call :logger "!LOG-SUCC!" "!INSTALL_MODU_END!"
   call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "%wait_timetry5%" "1" "N"
   goto :menu_trytond
   
:database_process   
   set "confirm=%~1"
   set "process=%~2"
   echo.
   :: 1.- Parar el servicio de postgres para desactivar posibles conexiones de usuarios
   call :logger "%INS%" "[1.-] !INSTALL_MODU_HEAD11! -stop %POSTGRES%" "3"
   :: docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps --status running -q | findstr "^" >nul 2>&1
   docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps "%POSTGRES%" | findstr /I "Up" >nul
   if %ERRORLEVEL% EQU 0 (
     docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" stop "%POSTGRES%" >nul 2>&1
     call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timetry!" "1" 
   )  
   :: 2.- Activar el servicio de postgres
   call :logger "%INS%" "[2.-] !INSTALL_MODU_HEAD12! - start %POSTGRES%" "3"
   docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" start "%POSTGRES%" >nul 2>&1 
   call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timetry!" "1" 

   if /i "%confirm%"=="YES" (
     :: 3.- Realizar una copia de seguridad de la base de datos
     call :logger "%INS%" "[3.-] !INSTALL_MODU_HEAD13! %DB_NAME%" "3"
     call "%DIR_SCRIPT%backup.bat" "%TRYTON%" "%process%"
     call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timetry!" "1" 
   )
   :: 4.- Eliminar la base de datos %DB_NAME% si existe
   call :logger "%INS%" "[4.-] !INSTALL_MODU_HEAD14! %DB_NAME%" "3"
   docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" dropdb -U postgres --if-exists "%DB_NAME%"
   call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timetry!" "1"
   :: 5.- Crear la base de datos %DB_NAME% 
   call :logger "%INS%" "[5.-] !INSTALL_MODU_HEAD15! %DB_NAME%" "3"
   docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" createdb -U postgres "%DB_NAME%"
   call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timetry!" "1"
   :: 6.- Probando conexión a la base de datos
   call :logger "%INS%" "[6.-] !INSTALL_MODU_HEAD16! %DB_NAME%" "3"
   set  "cmd=SELECT current_database();"
   call :run_trytond "%POSTGRES%" "!cmd!"
   exit /b

:: 07
:logs
  if /i "%ins_tryton_action%"=="%INS%" (
    call :logger "%INS%" "!INSTALL_MODU_23! %DB_NAME%" "3"
  ) else (
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "fill_in_field" "%TXT%" "7.- !INSTALL_MODU_23!" "3"
  )
  call "%DIR_SCRIPT%logger.bat" "%TRYTON%" "%SQL%"
  if /i "%ins_tryton_action%"=="%INS%" exit /b
  pause & goto :menu_trytond

::07
:compare_menu_modules
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "fill_in_field" "%TXT%" "8.- !INSTALL_MODU_24!" "3"
  call :compare_modules_install "%APP%" "!INSTALL_MODU_24!" "3"
  pause & goto :menu_trytond

:: 08
:listing_menu_modules
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "fill_in_field" "%TXT%" "9.- !INSTALL_MODU_25!" "3"
call :listing_modules "%APP%" "!INSTALL_MODU_25!" "3"
pause & goto :menu_trytond

:: 08 04-01
:listing_modules
  set "event=%~1"
  set "title=%~2"
  set "numer=%~3"
  set "cmd=SELECT name, state FROM ir_module ORDER BY name;"
  call :run_trytond "%POSTGRES%" "!cmd!" "%file_modules%" "%file_err%"
  if %ERRORLEVEL% NEQ 0  exit /b
  call "%DIR_SCRIPT%install_reports.bat" "%proyecto%" "8" "%event%" "%title%" "%numer%" "%file_modules%"
  exit /b
  
:: 04-02
:compare_modules_install
  set "event=%~1"
  set "title=%~2"
  set "numer=%~3"
  set  "cmd=SELECT name FROM ir_module WHERE state='activated' ORDER BY name;"
  call :run_trytond "%POSTGRES%" "!cmd!" "%file_activ%"
  if %ERRORLEVEL% NEQ 0  exit /b
  call "%DIR_SCRIPT%install_reports.bat" "%proyecto%" "9" "%event%" "%title%" "%numer%" "%file_activ%"
  exit /b

:extract_xml_from_log
  REM %~1 = fichero log completo
  REM %~2 = fichero donde guardar solo las líneas .xml
  set "basefile=%~1"
  set "outxml=%~2"
  REM Validar que el fichero de log existe
  if not exist "%basefile%" (
    echo ERROR: No existe el fichero de log "%basefile%".
    exit /b
  )
  REM Eliminar fichero destino si existe
  if exist "%outxml%" del "%outxml%" >nul 2>&1
  REM Filtrar con findstr (case insensitive)
  findstr /I "\.xml" "%basefile%" > "%outxml%"
  call "%DIR_SCRIPT%install_reports.bat" "%proyecto%" "7" "%event%" "%title%" "%numer%" "%outxml%"
  exit /b

 :run_trytond
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
    docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U postgres -d "!DB_NAME!" -At -c "%cmd%" %redir_out% %redir_err%
  )
  set "status=%ERRORLEVEL%"
  :: --- Esperar si OK ---
  if %status% EQU 0 (
    if /i "%ins_tryton_action%" EQU "%INS%" (
        call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timetry!" "1"
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

:head_modules
  echo.
  echo    ==============================================================
    call :logger "%MENU%" "!INSTALL_MODU_HEAD01! %DB_NAME%" "8"
  echo    ==============================================================
  echo.
    call :logger "%MENU%" "!INSTALL_MODU_HEAD02! %DB_NAME%" "8"
  echo         -------------------------------------------
  echo.
    call :logger "%MENU%" "!INSTALL_MODU_HEAD04! %proyecto%" "3"
    call :logger "%MENU%" "!INSTALL_MODU_HEAD07! [!CURRENT_VER_MENU!]" "3"
    call :logger "%MENU%" "!INSTALL_MODU_HEAD05! %DB_NAME%" "3"
    call :logger "%MENU%" "!INSTALL_MODU_HEAD08! [!CURRENT_PG_VERSION!]" "3"   
    call :logger "%MENU%" "!INSTALL_MODU_HEAD06! %DB_URI%" "3"
    call :logger "%MENU%" "!INSTALL_MODU_HEAD03! %DIR_HOME%%COMPOSE_FILE%" "3"
    set "MESSAGE=!INSTALL_MODU_HEAD33:USUARIO=%DB_USER%!"
    call :logger "%MENU%" "!MESSAGE:CLAVE=%DB_PASSWORD%!" "3"
    call :logger "%MENU%" "!INSTALL_MODU_HEADCO! !TRYTON_LANGUAGE!" "3"
    call :logger "%MENU%" "!INSTALL_MODU_HEADEM! !CURRENT_COMPANY_NAME!" "3"
  echo.
  echo    ==================================================================================
    call :logger "%MENU%" "!INSTALL_MODU_HEAD10! %DB_NAME%"  "8"
  echo    ==================================================================================
  echo.
    call :logger "%MENU%" "[+] 1.-!INSTALL_MODU_HEAD11!" "3"  
    call :logger "%MENU%" "[+] 2.-!INSTALL_MODU_HEAD12!" "3"
    call :logger "%MENU%" "[+] 3.-!INSTALL_MODU_HEAD13!" "3"
    call :logger "%MENU%" "[+] 4.-!INSTALL_MODU_HEAD14! %DB_NAME%" "3"
    call :logger "%MENU%" "[+] 5.-!INSTALL_MODU_HEAD15! %DB_NAME%" "3"
    call :logger "%MENU%" "[+] 6.-!INSTALL_MODU_HEAD16! %DB_NAME%" "3"
    call :logger "%MENU%" "[+] 7.-!INSTALL_MODU_HEAD17!" "3"
    call :logger "%MENU%" "7.1-%INSTALL_MODU_PRODC1% ( !C1: =, ! )" "8"
    call :logger "%MENU%" "7.2-%INSTALL_MODU_PRODC2% ( !C2: =, ! )" "8"
    call :logger "%MENU%" "7.3-%INSTALL_MODU_PRODC3% ( !C3: =, ! )" "8"
    call :logger "%MENU%" "7.4-%INSTALL_MODU_PRODC4% ( !C4: =, ! )" "8"
    call :logger "%MENU%" "7.5-%INSTALL_MODU_PRODC5% ( !C5: =, ! )" "8"
    call :logger "%MENU%" "7.6-%INSTALL_MODU_PRODC6% ( !C6: =, ! )" "8"
    call :logger "%MENU%" "7.7-%INSTALL_MODU_PRODC7% ( !C7: =, ! )" "8"
    call :logger "%MENU%" "7.8-%INSTALL_MODU_PRODC8% ( !C8: =, ! )" "8"
    set /a "znum=7"
    if /i "!LS!" NEQ "" if /i "!LX!" NEQ "" (
      set /a znum+=1
      call :logger "%MENU%" "[+]  !znum!.-!LS!" "3"
    )
    set /a znum+=1
    call :logger "%MENU%" "[+]  !%znum!.-!INSTALL_MODU_HEAD34!" "3"
    set /a znum+=1
    call :logger "%MENU%" "[+] !%znum!.-!INSTALL_MODU_HEAD18!" "3"
    set /a znum+=1
    call :logger "%MENU%" "[+] !znum!.-!INSTALL_MODU_HEAD19!" "3"
    set /a znum+=1
    call :logger "%MENU%" "[+] !znum!.-!INSTALL_MODU_HEAD20!" "3"
    call :logger "%MENU%" "!INSTALL_MODU_HEAD21!" "12"
    set /a znum+=1
    call :logger "%MENU%" "[+] !znum!.-!INSTALL_MODU_HEAD44!" "3"
    call :logger "%MENU%" "!znum!.1-!INSTALL_MODU_HEAD45!" "8"
    call :logger "%MENU%" "!znum!.2-!INSTALL_MODU_HEAD46!" "8"
    call :logger "%MENU%" "!znum!.3-!INSTALL_MODU_HEAD47!" "8"
    call :logger "%MENU%" "!znum!.4-!INSTALL_MODU_HEAD48!" "8"
    call :logger "%MENU%" "!znum!.5-!INSTALL_MODU_HEAD49!" "8"
    call :logger "%MENU%" "!znum!.6-!INSTALL_MODU_HEAD50!" "8"
    call :logger "%MENU%" "!znum!.7-!INSTALL_MODU_HEAD51! !CURRENT_COMPANY_NAME!" "8"
    call :logger "%MENU%" "!INSTALL_MODU_HEAD52! (!CURRENT_JOURNAL_CODE!) !WORD_NAME!: !CURRENT_JOURNAL_NAME!" "13"
    set "MESSAGE=!INSTALL_MODU_HEAD41:IMPUESTOS=%CURRENT_VAT_RATES%!"
    call :logger "%MENU%" "!znum!.8-!MESSAGE! !CURRENT_COMPANY_NAME!" "8"
  echo.
exit /b

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:exit
  endlocal
  exit /b 0
