@echo off
:: ===============================================================================
:: PROGRAM:   install.lang.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.1.25
:: DATE:      24/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Install trytond tryton version 7 y 8
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: Analiza si la llamada es del tcd.bat
set "proyecto=%~1"
set "ins_lang_action=%~2"
set "log_action=!LOG-INFO!"
set /a "wait_timelan=10"
set "file_lang_tmp=%DIR_TMP%\trytond_lang"

if /i "!ins_lang_action!"=="%INS%" set "log_action=%INS%"
call "%DIR_SCRIPT%install_header.bat" "%proyecto%" "%ins_lang_action%" "%LANG%" "install_language"
if %ERRORLEVEL% NEQ 0 goto :exit

set "BASE_MODULES_FILTERED=0"
:: 5.- Localizar los modulos de tryton (Fuera de setlocal para que las variables LL, LX, C1... persistan)
call "%DIR_SCRIPT%message.bat" "%CHECK%" "!INSTALL_MODU_35!"
call "%DIR_SCRIPT%base_modules.bat" "%proyecto%" "%ins_tryton_action%"

call :logger "%CHECK%" "BASE_I:[!BASE_I!] BASE_M:[!BASE_M!] BASE_R:[!BASE_R!]" 
call :logger "%CHECK%" "!WORD_VERSION!:[!CURRENT_VERSION!] TRYTON_BASE_MODULE:[!TRYTON_BASE_MODULE!]" 
call :logger "%CHECK%" "LX:[!LX!] LL:[!LL!]" 

set "COM1=TRYTOND_DATABASE_URI=!DB_URI! trytond-admin -c /etc/trytond.conf -d %DB_NAME%"
set "COM2=TRYTONPASSFILE=/tmp/.passwd"
set "COM3= --email !EMAIL! -vv"
:: Si es de install.bat seguimos en el proceso de instalacion

if not exist "%DIR_LOG%" mkdir "%DIR_LOG%"
if not exist "%DIR_TMP%" mkdir "%DIR_TMP%"

if /i "!ins_lang_action!"=="%INS%" (
  set "iso_lang="
  set "iso_code=!TRYTON_LANGUAGE!"
  set "ACCION=GEO"
  if /i "!iso_code!"=="es" (
    set "iso_code=ES"  
    set "iso_lang=1"
  )
  if /i "!iso_code!"=="fr" (
    set "iso_code=FR" 
    set "iso_lang=1"
  )
  if /i "!iso_code!"=="de" (
    set "iso_code=DE" 
    set "iso_lang=1"
  )

  if defined iso_lang (
    call :head_modules_lang
    call :language_modules_country
  )
  exit /b
)

:menu_trytond_lang
  cls
  set "option="
  set "MESSAGE="
  set "wlang="
  :: Banner
  call "%DIR_SCRIPT%banner.bat" %TRYTON%
  echo ==========================================================================================
  call :logger %MENU% "!INSTALL_MODU_LG!" "5"
  echo ==========================================================================================
  echo.
  call :logger "%MENU%" "1. !INSTALL_MODU_30!" "5"
  call :logger "%MENU%" "2. !INSTALL_MODU_31!" "5"
  call :logger "%MENU%" "3. !INSTALL_MODU_32!" "5"
  call :logger "%MENU%" "Q. !INSTALL_MODU_33!" "5"
  echo.
  call :logger "%MENU%" "!INSTALL_MODU_36!" "2"
  call :logger "%MENU%" "!INSTALL_MODU_37!" "2"
  echo.
  echo ==========================================================================================
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
    set "TRYTON_LANGUAGE=%wlang%"
    set "LX="
    set "LL="
    if /i "!TRYTON_LANGUAGE!" EQU "es"  set "LX=!LS!" & set "LL=!ES!"
    if /i "!TRYTON_LANGUAGE!" EQU "fr"  set "LX=!LR!" & set "LL=!FR!"
    if /i "!TRYTON_LANGUAGE!" EQU "de"  set "LX=!LE!" & set "LL=!DE!"
  )  
  if "%LX%"=="" if /i "%LL%"=="" (
    call :logger "!LOG-WARN!" "!INSTALL_MODU_34!"
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "%wait_timelan%" "1" "N"
    goto :menu_trytond_lang
  )
  set "iso_code=!TRYTON_LANGUAGE!"
  if /i "!iso_code!"=="es" set "iso_code=ES"
  if /i "!iso_code!"=="fr" set "iso_code=FR"
  if /i "!iso_code!"=="de" set "iso_code=DE"
  set "ACCION=GEO"
  call :head_modules_lang
  echo.
  set "confirm="
  set "MESSAGE=!INSTALL_MODU_EMPLG:PROYECTO=%wlang%!"
  set /p "confirm=%BS%        !C_M_GREEN!!MESSAGE!!C_M_RESET! "
  if /i "%confirm%" NEQ "YES" (
    echo.
    call :logger "!LOG-CANCEL!" "!LOG_INSTALL_CANCEL!"
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "5" "1" "N"
    goto :menu_trytond_lang
  )

  echo.
  :: 1.- Parar el servicio de postgres para desactivar posibles conexiones de usuarios
  call :logger "%log_action%" "[1.-] !INSTALL_MODU_HEAD11! - stop %POSTGRES%" "3"
  docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" ps "%POSTGRES%" | findstr /I "Up" >nul
  if %ERRORLEVEL% EQU 0 (
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
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%POSTGRES%" "!cmd!" "!DB_NAME!" "" "" "" ""

:language_modules_country
  set "noclear_file="
  if /i "%ins_lang_action%"=="%INS%" (
    call :logger "%log_action%" "!INSTALL_MODU_LG! !WORD_INSTALL! !WORD_LANGUAGE!:!TRYTON_LANGUAGE!" "3"
    set "noclear_file=YES"
    echo.
  )

  :: 1. Actualizar lista de módulos
  call :logger "%log_action%" "!INSTALL_MODU_HEAD34!" "3"
  set "cmd=!COM2! !COM1! --update-modules-list !COM3!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%SERVER%" "!cmd!" "!DB_NAME!" "" "%file_base%" "%noclear_file%" "" ""
  
  call :logger "%log_action%" "!INSTALL_MODU_HEAD34_ALL!" "3"
  set "cmd=!COM2! !COM1! --all !COM3!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%SERVER%" "!cmd!" "!DB_NAME!" "" "%file_base%" "%noclear_file%" "" ""

  :: 2. Activar el idioma seleccionado
  call :logger "%log_action%" "!INSTALL_MODU_HEADCO! -l CODE !TRYTON_LANGUAGE!" "3"
  set "cmd=!COM2! !COM1! -l CODE !TRYTON_LANGUAGE! !COM3!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%SERVER%" "!cmd!" "!DB_NAME!" "" "%file_base%" "YES" "" ""

  :: 3. Instalar módulos del país (!LL! contiene el nombre del módulo: account_es, etc.)
  call :logger "%log_action%" "%LX%" "3"
  set "cmd=!COM2! !COM1! -u !LL! --activate-dependencies !COM3!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%SERVER%" "!cmd!" "!DB_NAME!" "" "%file_base%" "YES" "" ""
 :: 4. Importar Paises , subdivisiones y códigos postales 
  call :logger "%log_action%" "!INSTALL_MODU_HEAD54! !TRYTON_LANGUAGE!" "3"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "%wait_timelan%" "1"
  docker exec -t ^
  -e COMPANY_NAME="!CURRENT_COMPANY_NAME!" ^
  -e COMPANY_CURRENCY="!CURRENT_COMPANY_CURRENCY!" ^
  -e APP_LANGUAGE="!LOCALE!" ^
  !CURRENT_TRYTON! python3 /tmp/auto_full_setup.py !DB_NAME! /tmp/trytond_setup.conf !iso_code! !ACCION!
  if %ERRORLEVEL% GEQ 10 (
    set "MESSAGE=ERROR %ERRORLEVEL%:"
    if %ERRORLEVEL% equ 10 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD55! !DB_NAME!."
    if %ERRORLEVEL% equ 15 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD56! !DB_NAME!."
    if %ERRORLEVEL% equ 20 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD57! [!iso_code!]."
    if %ERRORLEVEL% equ 21 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD58! [!iso_code!]."
    call :logger "!LOG-ERROR!" "!MESSAGE!"
  )
  :: 5 Traemos el log actual del contenedor a un temporal para grabar los datos en el pc
  set "temp_file=%file_lang_tmp%_!iso_code!.txt"
  set "logger_tmp=%DIR_LOG%\%TRYTON%_logger_!iso_code!.log"
  set "MESSAGE=!BCK_COPY_CLIENT:ARCHIVO=/tmp/trytond_proteus.txt!"
  set "acc_message=!MESSAGE:DESTINO=%logger_tmp%!"
  call :logger "%log_action%" "[!ACCION!] !acc_message!" "3"
  docker cp !CURRENT_TRYTON!:/tmp/trytond_proteus.txt %temp_file% >nul
  if %ERRORLEVEL% EQU 0 (
    echo [!DATE!] [!TIME!] [!ACCION!]  > "%logger_tmp%"
    type "%temp_file%" >> "%logger_tmp%"
    docker exec -u 0 !CURRENT_TRYTON! rm -f /tmp/trytond_proteus.txt >nul
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "%wait_timelan%" "1" "N"
  )
  :: 6 Ejecuta la inyección combinada
  call :logger "%log_action%" "!INSTALL_MODU_HEAD68! !TRYTON_LANGUAGE!" "3"
  set "ACCION=LANG"
  docker exec -t ^
  -e COMPANY_NAME="!CURRENT_COMPANY_NAME!" ^
  -e COMPANY_CURRENCY="!CURRENT_COMPANY_CURRENCY!" ^
  -e APP_LANGUAGE="!LOCALE!" ^
  !CURRENT_TRYTON! python3 /tmp/auto_full_setup.py !DB_NAME! /tmp/trytond_setup.conf !iso_code! !ACCION!
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timelan!" "1"
  if %ERRORLEVEL% GEQ 10 (
    set "MESSAGE=ERROR %ERRORLEVEL%:"
    if %ERRORLEVEL% equ 10 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD55! !DB_NAME!."
    if %ERRORLEVEL% equ 15 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD56! !DB_NAME!."
    if %ERRORLEVEL% equ 30 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD59! [!LOCALE!]"
    call :logger "!LOG-ERROR!" "!MESSAGE!"
  ) 

  :: 7 Traemos el log actual del contenedor a un temporal para grabar los datos en el pc
  call :logger "%log_action%" "[!ACCION!] !acc_message!" "3"
  docker cp !CURRENT_TRYTON!:/tmp/trytond_proteus.txt %temp_file% >nul
  if %ERRORLEVEL% EQU 0 (
    echo [!DATE!] [!TIME!] [!ACCION!]  >> "%logger_tmp%"
    type "%temp_file%" >> "%logger_tmp%"
    docker exec -u 0 !CURRENT_TRYTON! rm -f /tmp/trytond_proteus.txt >nul
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "%wait_timelan%" "1" "N"
  )

  :: ======Localizar los idiomas configurados en Tryton=============
  call :logger "%log_action%" "!INSTALL_MODU_HEAD67! !DB_NAME!" "3"
  set "temp_file=%file_lang_tmp%_count.txt"
  set "cmd=SELECT count(*) FROM ir_lang WHERE translatable=true;"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%POSTGRES%" "!cmd!" "!DB_NAME!" "%temp_file%" "" "" ""
  set "LANGUAGES=0"
  for /f "usebackq tokens=* delims=" %%i in ("%temp_file%") do set "LANGUAGES=%%i"
  call :logger "%log_action%" "!WORD_ACT_LANGUAGES!: !LANGUAGES! !WORD_CONFIGURED!" "3"

  if /i "%ins_lang_action%"=="%INS%" exit /b

  call :logger "%log_action%" "!INSTALL_MODU_HEAD34!" "3"
  set "cmd=!COM2! !COM1! --update-modules-list !COM3!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%SERVER%" "!cmd!" "!DB_NAME!" "" "%file_base%" "YES" "" ""

  :: Finalizar actualización global tras instalar localización
  call :logger "%log_action%" "!INSTALL_MODU_HEAD34_ALL!" "3"
  set "cmd=!COM2! !COM1! --all !COM3!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%SERVER%" "!cmd!" "!DB_NAME!" "" "%file_base%" "YES" "" ""

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

:: 08 04-01
:listing_modules_lang
  set "event=%~1"
  set "title=%~2"
  set "numer=%~3"
  set "cmd=SELECT name, state FROM ir_module ORDER BY name;"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%POSTGRES%" "!cmd!" "!DB_NAME!" "%file_modules%" "%file_err%" "" "" ""
  if %ERRORLEVEL% NEQ 0  exit /b
  call "%DIR_SCRIPT%install_reports.bat" "%proyecto%" "8" "%event%" "%title%" "%numer%" "%file_modules%" "%LANG%"
  exit /b
  
:: 04-02
:compare_modules_install_lang
  set "event=%~1"
  set "title=%~2"
  set "numer=%~3"
  set  "cmd=SELECT name FROM ir_module WHERE state='activated' ORDER BY name;"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%POSTGRES%" "!cmd!" "!DB_NAME!" "%file_activ%" "" "" "" ""
  if %ERRORLEVEL% NEQ 0  exit /b
  call "%DIR_SCRIPT%install_reports.bat" "%proyecto%" "5" "%event%" "%title%" "%numer%" "%file_activ%" "%LANG%"
  exit /b

:head_modules_lang
  echo.
  call :logger "%MENU%" "!INSTALL_MODU_HEAD02! %DB_NAME%" "8"
  echo         -------------------------------------------
  echo.
  call :logger "%MENU%" "!INSTALL_MODU_HEAD04! %proyecto%" "3"
  call :logger "%MENU%" "!INSTALL_MODU_HEAD07! [!CURRENT_VER_MENU!]" "3"
  call :logger "%MENU%" "!INSTALL_MODU_HEAD05! %DB_NAME%" "3" 
  call :logger "%MENU%" "!INSTALL_MODU_HEADEM! !CURRENT_COMPANY_NAME!" "3"
  echo.
  echo    ==================================================================================
  call :logger "%MENU%" "!INSTALL_MODU_HEAD10! %DB_NAME%"  "8"
  echo    ==================================================================================
  echo.
  call :logger "%MENU%" "[+] 1.-!INSTALL_MODU_HEADCO! !iso_code!" "3"
  call :logger "%MENU%" "[+] 2.-!INSTALL_MODU_HEADMO! !LX!" "3"
  call :logger "%MENU%" "[+] 3.-!INSTALL_MODU_HEAD61!" "3"
  call :logger "%MENU%" "!INSTALL_MODU_HEAD62!" "16"
  call :logger "%MENU%" "[+] 4.-!INSTALL_MODU_HEAD63!" "3"
  call :logger "%MENU%" "!INSTALL_MODU_HEAD64!" "16"
  call :logger "%MENU%" "[+] 5.-!INSTALL_MODU_HEAD65!" "3"
  call :logger "%MENU%" "!INSTALL_MODU_HEAD66:FILE=%iso_code%.zip!" "16"
  call :logger "%MENU%" "[+] 6.-!INSTALL_MODU_HEAD69! !iso_code!" "3"
  echo.
  exit /b

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:exit
  endlocal
  exit /b 0
