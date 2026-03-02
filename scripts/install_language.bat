@echo off
:: ===============================================================================
:: PROGRAM:   install.lang.bat
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
set "ins_lang_action=%~2"
set "log_action=!LOG-INFO!"
set /a "wait_timelan=10"

call "%DIR_SCRIPT%install_header.bat" "%proyecto%" "%ins_lang_action%" "%LANG%" "install_language"
if %errorlevel% EQU 2 (
   set "MESSAGE=!STAT_ERR_NOT_INSTALLED:PROYECTO=%proyecto%!"
   call :logger "!LOG-ERROR!" "!MESSAGE!"
   pause & goto :exit
)
if %errorlevel% EQU 4 (
   set "MESSAGE=!BCK_CONT_STOP:PROYECTO=%proyecto%!"
   call :logger "!LOG-ERROR!" "!MESSAGE!"
   pause & goto :exit
 )

 :: Si es de install.bat seguimos en el proceso de instalacion
 if /i "!ins_lang_action!"=="%INS%" (
  set "log_action=%INS%"
  goto :language_modules_country
 )

:menu_trytond_lang
  cls
  set "option="
  set "MESSAGE="
  set "wlang="
  :: Banner
  call "%DIR_SCRIPT%banner.bat" %TRYTON%
  echo =================================================================================
  call :logger %MENU% "!INSTALL_MODU_LG!" "5"
  echo =================================================================================
  call :logger "%MENU%" "1. !INSTALL_MODU_30!" "5"
  call :logger "%MENU%" "2. !INSTALL_MODU_31!" "5"
  call :logger "%MENU%" "3. !INSTALL_MODU_32!" "5"
  call :logger "%MENU%" "Q. !INSTALL_MODU_33!" "5"
  echo ========================================================
  echo.
  set /p "option=%BS%        !C_M_YELLOW!%SELECT_OPT%!C_M_RESET! "
  if /i "%option%"=="Q" goto :exit
  if /i "%option%"=="1" set "wlang=es"
  if /i "%option%"=="2" set "wlang=fr"
  if /i "%option%"=="3" set "wlang=de"
  if /i "%wlang%"=="" (
    call :logger "!LOG-WARN!" "!INSTALL_MODU_34!"
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "5" "1" "N"
    goto :menu_trytond_lang
  )
  if /i "%wlang%" NEQ "!TRYTON_LANGUAGE!" (
    set "!TRYTON_LANGUAGE!=%wlang%"
    set "LX="
    set "LL="
    if /i "!TRYTON_LANGUAGE!" EQU "es"  set "LX=!LS!" & set "LL=!ES!"
    if /i "!TRYTON_LANGUAGE!" EQU "fr"  set "LX=!LR!" & set "LL=!FR!"
    if /i "!TRYTON_LANGUAGE!" EQU "de"  set "LX=!LE!" & set "LL=!DE!"
  )  
  if "%LX%"=="" if /i "%LL%"=="" (
    call :logger "!LOG-WARN!" "!INSTALL_MODU_34!"
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "5" "1" "N"
    goto :menu_trytond_lang
  )
  echo.
  set "confirm="
  set "MESSAGE=!INSTALL_MODU_EMPLG:PROYECTO=%wlang%!"
  set /p "confirm=%BS%        !C_M_GREEN!!MESSAGE!!C_M_RESET! "
  if /i not "%confirm%"=="YES" (
    echo.
    call :logger "!LOG-CANCEL!" "!LOG_INSTALL_CANCEL!"
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "5" "1" "N"
    goto :menu_trytond_lang
  )

  call :database_process_lang
  echo.

:language_modules_country
  call :logger "%log_action%" "!INSTALL_MODU_LG!" "3"
  set "COM1=TRYTOND_DATABASE_URI=!DB_URI! trytond-admin -c /etc/trytond.conf -d %DB_NAME%"
  set "COM2=TRYTONPASSFILE=/tmp/.passwd"
  set "COM3= --email !EMAIL! -vv"

  set "noclear_file="
  if /i "%ins_lang_action%"=="%INS%" set "noclear_file=YES"
  call :logger "%log_action%" "!INSTALL_MODU_HEAD34!" "3"
  set "cmd=!COM2! !COM1! --update-modules-list !COM3!"
  call :run_trytond_lang "%SERVER%" "!cmd!" "" "%file_base%" "%noclear_file%"

  call :logger "%log_action%" "!INSTALL_MODU_HEADCO! -l CODE !TRYTON_LANGUAGE!" "3"
  set "cmd=!COM2! !COM1! -l CODE !TRYTON_LANGUAGE! !COM3!"
  call :run_trytond_lang "%SERVER%" "!cmd!" "" "%file_base%" "YES"

  call :logger "%log_action%" "%LX%" "3"
  set "cmd=!COM2! !COM1! -u !LL! --activate-dependencies !COM3!"
  call :run_trytond_lang "%SERVER%" "!cmd!" "" "%file_base%" "YES"

  if /i "%ins_lang_action%"=="%INS%" exit /b
  
  call :logger "%log_action%" "!INSTALL_MODU_HEAD34!" "3"
  set "cmd=!COM2! !COM1! --update-modules-list !COM3!"
  call :run_trytond_lang "%SERVER%" "!cmd!" "" "%file_base%" "YES"
  :: Reports Verificar y comprobar que todos los módulos están activated

  call :logger "%log_action%" "!INSTALL_MODU_HEAD18!" "3"
  call :compare_modules_install_lang "%MENU%" "!INSTALL_MODU_HEAD18!" "3"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timelan!"

:: Reports Listar todos los modulos 
  call :logger "%log_action%" "!INSTALL_MODU_HEAD19!" "3"
  call :listing_modules_lang "%MENU%" "!INSTALL_MODU_HEAD19!" "3"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timelan!"

  call :logger "!LOG-SUCC!" "!INSTALL_MODU_END!" "3"
  echo.
  pause & goto :menu_trytond_lang

:database_process_lang
   echo.
   :: 1.- Parar el servicio de postgres para desactivar posibles conexiones de usuarios
   call :logger "%log_action%" "[1.-] !INSTALL_MODU_HEAD11! - stop %POSTGRES%" "3"
   docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps "%POSTGRES%" | findstr /I "Up" >nul
   if %errorlevel% EQU 0 (
     docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" stop "%POSTGRES%" >nul 2>&1
     call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timelan!" "1"
   )  
   :: 2.- Activar el servicio de postgres
   call :logger "%log_action%" "[2.-] !INSTALL_MODU_HEAD12! - start %POSTGRES%" "3"
   docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" start "%POSTGRES%" >nul 2>&1 
   call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timelan!" "1"
   :: 3.- Probando conexión a la base de datos
   call :logger "%log_action%" "[3.-] !INSTALL_MODU_HEAD16! %DB_NAME%" "3"
   set  "cmd=SELECT current_database();"
   call :run_trytond_lang "%POSTGRES%" "!cmd!"
   call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timelan!" "1"
   exit /b

:: 08 04-01
:listing_modules_lang
  set "event=%~1"
  set "title=%~2"
  set "numer=%~3"
  set "cmd=SELECT name, state FROM ir_module ORDER BY name;"
  call :run_trytond_lang "%POSTGRES%" "!cmd!" "%file_modules%" "%file_err%"
  if %ERRORLEVEL% NEQ 0  exit /b
  call "%DIR_SCRIPT%install_reports.bat" "%proyecto%" "8" "%event%" "%title%" "%numer%" "%file_modules%" "%LANG%"
  exit /b
  
:: 04-02
:compare_modules_install_lang
  set "event=%~1"
  set "title=%~2"
  set "numer=%~3"
  set  "cmd=SELECT name FROM ir_module WHERE state='activated' ORDER BY name;"
  call :run_trytond_lang "%POSTGRES%" "!cmd!" "%file_activ%"
  if %ERRORLEVEL% NEQ 0  exit /b
  call "%DIR_SCRIPT%install_reports.bat" "%proyecto%" "5" "%event%" "%title%" "%numer%" "%file_activ%" "%LANG%"
  exit /b

 :run_trytond_lang
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
  set "status=%errorlevel%"
  :: --- Esperar si OK ---
  if %status% EQU 0 (
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timelan!"
    exit /b 0
  )
  if %status% NEQ 0 (
    if not "%errfile%"=="" if exist "%errfile%" call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "display_file_event_all" "!LOG-ERROR!" "%errfile%"
    if not "%logfile%"=="" if exist "%logfile%" call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "display_file_event_all" "!LOG-INFO!" "%logfile%"
  )
  exit /b %status%

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:exit
  endlocal
  exit /b 0
