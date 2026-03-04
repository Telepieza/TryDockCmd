@echo off
:: ===============================================================================
:: PROGRAM:   tcd.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    [Telepieza - Mariano Vallespín - Gemini (Google AI)]
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      01/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Tryton Docker Manager (TCD)
:: ==============================================================================
cls
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: restaura el color default de Windows
color
:: Directorio raiz
set "DIR_HOME=%~dp0"
set "APPLICATION=TRYDOCKCMD DOCKER MANAGER"
:: Definir variables globales, añadir el idioma que se desee y en la variable LOCALE incluir el idioma.
set "es-ES=es-ES"
set "en-US=en-US"
:: Asignar por defecto el idioma si no encuentra el fichero .env
set "LOCALE=%es-ES%"
:: Constantes 
set "DIR_LOG=%DIR_HOME%log"
set "DIR_BACKUP=%DIR_HOME%backup"
set "DIR_LANG=%DIR_HOME%lang"
set "DIR_TMP=%DIR_HOME%tmp"
set "DIR_SQL=%DIR_HOME%sql"
set "DIR_CONFIG=%DIR_HOME%config"
set "DIR_SCRIPT=%DIR_HOME%scripts\"
:: Proyecto, variable principal del trydockcmd
set "TRYTON=tryton" 
:: Servicios, son tres server cron y postgres               
set "SERVER=server"
set "CRON=cron"
set "POSTGRES=postgres"
:: Ficheros para importar los datos necesarios para el proyecto
set "ENV_FILE=.env"
set "COMPOSE_FILE=compose.yml"
set "COMPOSE_DATA=compose_import.yml"
set "READ_FILEPS1=read-compose.ps1"
set "CONF_FILE_TRY=trytond.conf"
:: Tipo de mensajes para visualizar colores
set "ERR=[ERROR]"
set "TXT=[TXT]"
set "APP=[APP]"
set "SEE=[SEE]"
set "SQL=[SQL]"
set "CHECK=[CHECK]"
set "MENU=[MENU]"
set "INS=[INS]"
set "CALC=[CALC]"
set "DAT=[DATE]"
set "TIM=[TIME]"
set "DEMO=[DEMO]"
set "LANG=[LANG]"
set "PYTH=[PYTHON]"
set "ERROR_PATTERNS=error fatal fail exception traceback panic"
set "EXT_TXT=.txt"
set "EXT_CSV=.csv"
set "EXT_SQL=.sql"
set "EXT_LOG=.log"
:: Datos por omision, serán cambiado leyendo read-compose.ps1
set "TRYTON_TRYTON=%TRYTON%/%TRYTON%"
set "TRYTON_POSTGRES=%TRYTON%-%POSTGRES%"
set "LATEST=latest"
set "TRYTON_VERSION=%LATEST%"
set "POSTGRES_VERSION=%LATEST%"
set "SERVER_TARGET=8000"
set "SERVER_PUBLISHED=8000"
set "DB_NAME_DEMO=tryton_demo"
:: inspectdocker.bat localiza en docker los nombres de los contenedores
set "CURRENT_TRYTON="
set "CURRENT_CRON="
set "CURRENT_POSTGRES="
set "CURRENT_VERSION="
set "CURRENT_VER_MENU="
set "CURRENT_PG_VERSION="
set "CURRENT_PGALL_VERSION="
set "CURRENT_COMPANY_NAME="
set "CURRENT_COMPANY_CURRENCY="
:: Variables de trabajo
set "LOAD_FILE=0"
set "MESSAGE="
set "SEARCH_TERM="
set "ACTIVE_CONT="
:: Variables de trabajo. readcompose.bat se encarga de buscar y grabar sus valores
set "SERVER_IMAGE_NAME=" 
set "SERVER_IMAGE_VERSION="  
set "SERVER_PORT_TARGET="
set "SERVER_PORT_PUBLISHED="  
set "CRON_IMAGE="
set "CRON_IMAGE_NAME="  
set "CRON_IMAGE_VERSION="  
set "POSTGRES_IMAGE="
set "POSTGRES_IMAGE_NAME=" 
set "POSTGRES_IMAGE_VERSION="  
:: Fecha formato YYYYMMDD para el LOG
call "%DIR_SCRIPT%cycletime.bat" "%DAT%" "%date%" 
::set "FECHA_LOG=%date:~-4,4%%date:~-7,2%%date:~-10,2%"
set "FECHA_LOG=!fmtf_yyyymmdd!"
set "FECHA_LOG1="
set "LOGGER=%DIR_LOG%\%TRYTON%_%FECHA_LOG%%EXT_LOG%"
set "LOGGER_TEMP=%DIR_LOG%\%TRYTON%_error%EXT_LOG%"
set /a "wait_time=8"
set "C_M_YELLOW="
set "C_M_GREEN="
set "C_M_RESET="
set "ANSI_SUPPORTED=0"
:: Crear directorios si no existen
if not exist "%DIR_LOG%"    mkdir "%DIR_LOG%"
if not exist "%DIR_BACKUP%" mkdir "%DIR_BACKUP%"
if not exist "%DIR_LANG%"   mkdir "%DIR_LANG%"
if not exist "%DIR_SCRIPT%" mkdir "%DIR_SCRIPT%"
if not exist "%DIR_SQL%"    mkdir "%DIR_SQL%"
if not exist "%DIR_CONFIG%" mkdir "%DIR_CONFIG%"
if not exist "%DIR_TMP%"    mkdir "%DIR_TMP%"
:: graba en el log fecha hora y nombre del script de arranque
set "PROGRAM=tcd"
call :logger "%APP%" "%PROGRAM%"
call "%DIR_SCRIPT%banner.bat" "%TRYTON%"
call "%DIR_SCRIPT%cycletime.bat" "%DAT%" "%date%" 
set "trydockcmd=%APPLICATION% - %fmt_ddmmyyyy%"
set "itime_tcd=%time%"
call "%DIR_SCRIPT%cycletime.bat" "%TIM%" "%itime_tcd%" 
set "trydockcmd=%trydockcmd% - %fmt_hhmmss%"
echo.
echo   ================================================================================
call :logger "%MENU%" "%trydockcmd%" "15"
echo   ================================================================================
echo.
call :logger "%MENU%" "%APPLICATION% - Starting ..........................................." "4"
echo.
:: Analiza si existe y lee el fichero en DIR_LANG de idioma es-ES.txt o en-US.txt.
call :logger "%TXT%" "[+] 1.-Lenguaje APP : %LOCALE% ROUTE: %DIR_LANG%\%LOCALE%.txt" "3"
call :check_file_lang
if "!LOAD_FILE!"=="1" pause & goto :exit
:: Analiza si existe el fichero .env en DIR_HOME
call :logger "%TXT%" "[+] 2.-!LOG_INFO_FILE! %ENV_FILE%. !WORD_ROUTE!: %DIR_HOME%%ENV_FILE%" "3"
call :check_file_env
if "!LOAD_FILE!"=="1" pause & goto :exit
:: Cargar variables de entorno desde .env
for /f "usebackq delims=" %%a in ("%DIR_HOME%%ENV_FILE%") do (
  set "linea=%%a"
  if "!linea:~0,1!" NEQ "#" set "%%a"
)
call :logger "%TXT%" "[+] 3.-!WORD_LANGUAGE! !WORD_FILE! .env: !LANGUAGE! !WORD_ROUTE!: %DIR_HOME%!LANGUAGE!.txt" "3"
:: Si language del fichero .env es diferente a variable LOCALE vuelve a leer con LANGUAGE
if /i "!LANGUAGE!" NEQ "%LOCALE%" (
  call :logger "%TXT%" "!WORD_LANGUAGE! !WORD_FILE! .env: !LANGUAGE! !WORD_ROUTE!: %DIR_HOME%!LANGUAGE!.txt" "3"
  call :check_file_lang
  if "!LOAD_FILE!"=="1" pause & goto :exit
)
call :logger "%TXT%" "[+] 4.-!LOG_INFO_FILE! !LOG_WORK_COMPOSE!. !WORD_ROUTE!: %DIR_HOME%%COMPOSE_FILE%" "3"
:: Analiza si existe el fichero compose.yml en DIR_HOME
call :check_file_compose
if "!LOAD_FILE!"=="1" pause & goto :exit
:: incluir lectura read-compose.ps1 (Leer datos de configuracion compose.yml )
call :logger "%TXT%" "[+] 5.-!LOG_INFO_DATA! !LOG_WORK_COMPOSE!. !WORD_ROUTE!: %DIR_HOME%%COMPOSE_FILE%" "3"
call "%DIR_SCRIPT%readcompose.bat" "%TRYTON%"
if "!LOAD_FILE!" neq "0" (
  call :check_file_ps1
  if "!LOAD_FILE!"=="1" goto :exit
)
call :logger "%TXT%" "[+] 6.-!LOG_INFO_HEAD! !MENU_TITLE! (!MENU_TRYDOCK!)" "3"
@REM :: --- Validación inicial ---
call "%DIR_SCRIPT%header.bat" "%TRYTON%"
set "MESSAGE="
if %errorlevel% equ 2 set MESSAGE="!DKR_NOT_READY!"
if %errorlevel% equ 3 set MESSAGE="!DKR_NOT_ENV!"
if not "%MESSAGE%"=="" ( 
   call :logger "%ERR%" "%MESSAGE%"
   pause & goto :exit
)

call :logger "%TXT%" "[+] 7.-!LOG_INFO_DATA! EMPRESA/MONEDA. !WORD_ROUTE!: %DIR_CONFIG%/%CONF_FILE_TRY%" "3"
if exist "%DIR_CONFIG%/%CONF_FILE_TRY%" (
    for /f "usebackq tokens=1,2 delims== " %%A in ("%DIR_CONFIG%/%CONF_FILE_TRY%") do (
        if /i "%%A"=="name" set "CURRENT_COMPANY_NAME=%%B"
        if /i "%%A"=="currency" set "CURRENT_COMPANY_CURRENCY=%%B"
    )
)

:: Validar si se cargaron los datos, si no, usar fallbacks de seguridad
if "!CURRENT_COMPANY_NAME!"=="" set "CURRENT_COMPANY_NAME=Company"
if "!CURRENT_COMPANY_CURRENCY!"=="" set "CURRENT_COMPANY_CURRENCY=EUR"

set "action_ins=%INS%"
:verify_docker
  set "LOAD_FILE=0"
  call :logger "%MENU%" "[+] 8.-!LOG_INFO_DOCKER!" "3"
  :: Verifica si las imágenes y los contenedores existen en Docker.
  :: El control es para que todas las demás opciones funcionen más controladas y rápidas.
  call "%DIR_SCRIPT%checkdocker.bat" "%TRYTON%"
  if %errorlevel% equ 0 (
    set "action_ins=%APP%"
    call :logger "%MENU%" "[+] 9.-!LOG_INFO_VERSION!" "3"
    call "%DIR_SCRIPT%checkversion.bat" "%TRYTON%"
    if /i "!CURRENT_PGALL_VERSION!"=="%LATEST%" set "CURRENT_PGALL_VERSION=PostgreSQL %LATEST%"
    call :logger "%MENU%" "9.1.- %APPLICATION% - !START_MSG! - %TRYTON%: [!CURRENT_VER_MENU!] " "7"
    call :logger "%MENU%" "9.2.- %APPLICATION% - !START_MSG! - %POSTGRES%: [!CURRENT_PGALL_VERSION!]" "7"
    call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "timeout_start" "!wait_time!" "1"
  ) 
  if "!CURRENT_VER_MENU!" EQU "" set "CURRENT_VER_MENU=%LATEST%"
  call :logger "%MENU%" "[+] 10.-!LOG_INFO_DOCKER!" "3"
  call :logger "%LOG-SUCC%" "tcd !LOG_INFO_PROCES!"
  for /f %%A in ('"prompt $H & echo on & for %%B in (1) do rem"') do set "BS=%%A"
  echo.
  :: No se ha localizado las imágenes y contenedores, siendo el arranque tcd la primera vez, se activa la instalación automática
  if "!CURRENT_VERSION!"=="" (
    call :logger "%CHECK%" "[+] !INSTALL_TITLE!" "3"
    call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "timeout_start" "!wait_time!" "1"
    goto :install
  )
  call :logger "%TXT%" "!START_MSG! !MENU_TRYDOCK! !MENU-OPTION_MAIN!"
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "timeout_start" "5" "1" "N"


  
  :: call "%DIR_SCRIPT%install_python.bat" "%TRYTON%" "%INS%"

:menu
  cls
  :: Banner
  call "%DIR_SCRIPT%banner.bat" "%TRYTON%"
  echo     ==========================================================================
  call :logger "%MENU%" "%MENU_TITLE% - %TRYTON%:[!CURRENT_VER_MENU!] - [!CURRENT_PG_VERSION!]" "10"
  echo     ==========================================================================
  call :logger "%MENU%" " 0. %MENU-OPTION_0% (%MENU-ERP%)" "5"
  call :logger "%MENU%" " 1. %MENU-OPTION_1% (%MENU-STATUS%)" "5"
  call :logger "%MENU%" " 2. %MENU-OPTION_2% (%MENU-START%)" "5"
  call :logger "%MENU%" " 3. %MENU-OPTION_3% (%MENU-STOP%)" "5"
  call :logger "%MENU%" " 4. %MENU-OPTION_4% (%MENU-LOGS%)" "5"
  call :logger "%MENU%" " 5. %MENU-OPTION_5% (%MENU-ERRORS%)" "5"
  call :logger "%MENU%" " 6. %MENU-OPTION_6% (%MENU-BACKUP%)" "5"
  call :logger "%MENU%" " 7. %MENU-OPTION_7% (%MENU-RESTORE%)" "5"
  call :logger "%MENU%" " 8. %MENU-OPTION_8% (%MENU-TRYTOND%)" "5" 
  call :logger "%MENU%" " 9. !MENU-OPTION_9:VERSION=%CURRENT_VERSION%! (%MENU-DUMP%)" "5"
  call :logger "%MENU%" "10. %MENU-OPTION_10% (%MENU-CLIENT%)" "5"
  call :logger "%MENU%" " Q. %MENU-OPTION_Q% (%MENU-QUIT%)" "5"
  echo     ==========================================================================
  echo.
:: No se ha localizado las imágenes y contenedores, siendo el arranque tcd la primera vez, se activa la instalación automática
  
  set "option="
  set "MESSAGE="
  set /p "option=%BS%        !C_M_YELLOW!%SELECT_OPT%!C_M_RESET! "
  if "%option%"=="0" goto :install
  if "%option%"=="1" goto :status
  if "%option%"=="2" goto :start
  if "%option%"=="3" goto :stop
  if "%option%"=="4" goto :logs
  if "%option%"=="5" goto :errors
  if "%option%"=="6" goto :backup
  if "%option%"=="7" goto :restore
  if "%option%"=="8" goto :trytond_production
  if "%option%"=="9" goto :trytond_demo
  if "%option%"=="10" goto :trytond_client
  if /i "%option%"=="q" goto :exit
  :: Si no es ninguna de las anteriores
  set "MESSAGE=%option% %LOG_ERR_OPT%"
  call :logger "!LOG-WARK!" "!MESSAGE!"
  pause & goto :menu

:install
  if /i "!CURRENT_VERSION!" NEQ "" (
    echo.
    set "MESSAGE=!LOG_INSTALL_VERSION:PROYECTO=%CURRENT_VERSION%!"
    call :logger "!LOG-WARN!" "!MESSAGE!"
    echo.
    call :logger "%MENU%" "!LOG_INSTALL_OPC!" "3"
    echo.
    call :logger "%MENU%" "- !MENU-OPTION_8!" "5" 
    call :logger "%MENU%" "- !MENU-OPTION_9:VERSION=%CURRENT_VERSION%!" "5"
    call :logger "%MENU%" "- !LOG_INSTALL_OP1!" "5"
    echo.
    pause & goto :menu
  )
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "fill_in_field" "%TXT%" "0.- %MENU-OPTION_0%" "3"
  :: action_ins = APP o INS
  call %DIR_SCRIPT%install.bat "%TRYTON%" "%action_ins%"
  :: Error o cancel en install
  if %errorlevel% neq 0 goto :menu
  :: No ha localizado la version
  if "!CURRENT_VERSION!"=="" goto :verify_docker
  pause & goto :menu
:status
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "fill_in_field" "%TXT%" "1.- %MENU-OPTION_1%" "3"
  call "%DIR_SCRIPT%status.bat" "%TRYTON%" "%APP%"
  pause & goto :menu
:start
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "fill_in_field" "%TXT%" "2.- %MENU-OPTION_2%" "3"
  call "%DIR_SCRIPT%startup.bat" "%TRYTON%" "%APP%"
  goto :menu
:stop
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "fill_in_field" "%TXT%" "3.- %MENU-OPTION_3%" "3"
  call "%DIR_SCRIPT%startdown.bat" "%TRYTON%" "%APP%"
  goto :menu
:logs
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "fill_in_field" "%TXT%" "4.- %MENU-OPTION_4%" "3"
  call "%DIR_SCRIPT%logger.bat" "%TRYTON%" "%APP%"
  goto :menu
:errors
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "fill_in_field" "%TXT%" "5.- %MENU-OPTION_5%" "3"
  call "%DIR_SCRIPT%errors.bat" "%TRYTON%" "%APP%"
  pause & goto :menu
:backup
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "fill_in_field" "%TXT%" "6.- %MENU-OPTION_6%" "3"
  call "%DIR_SCRIPT%backup.bat" "%TRYTON%" "%APP%"
  if %errorlevel% equ 0 pause
  goto :menu
:restore
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "fill_in_field" "%TXT%" "7.- %MENU-OPTION_7%" "3"
  call "%DIR_SCRIPT%restore.bat" "%TRYTON%" "%DIR_BACKUP%"
  pause & goto :menu
:trytond_production
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "fill_in_field" "%TXT%" "8.- %MENU-OPTION_8%" "3"
  call "%DIR_SCRIPT%install_tryton.bat" "%TRYTON%" "%APP%"
  goto :menu
:trytond_demo
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "fill_in_field" "%TXT%" "9.- !MENU-OPTION_9:VERSION=%CURRENT_VERSION%!" "3"
  call "%DIR_SCRIPT%install_demo.bat" "%TRYTON%" "%APP%"
  goto :menu
:trytond_client
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "fill_in_field" "%TXT%" "10.- %MENU-OPTION_10%" "3"
  call "%DIR_SCRIPT%client.bat" "%TRYTON%" "%APP%"
  goto :menu

:check_file_env
  :: Analiza si existe el fichero .env en DIR_HOME. Se ha leido el fichero de idiomas.
  if not exist "%DIR_HOME%%ENV_FILE%" (
     call "%DIR_SCRIPT%banner.bat" "%TRYTON%"
     set "msg_cont=!WORD_ROUTE! %DIR_HOME%%ENV_FILE%"
     set "MESSAGE=!LOG_ERR_ENV! !msg_cont!"
     call :logger "%ERR%" "!MESSAGE!"
     set "LOAD_FILE=1"
  )
  exit /b

  :check_file_compose
  :: Analiza si existe el fichero compose.yml en DIR_HOME. Se ha leido el fichero de idiomas.
  if not exist "%DIR_HOME%%COMPOSE_FILE%" (
     call "%DIR_SCRIPT%banner.bat" "%TRYTON%"
     set "msg_cont=!WORD_ROUTE! %DIR_HOME%%COMPOSE_FILE%"
     set "MESSAGE=!LOG_ERR_COMPOSE! !msg_cont!"
     call :logger "%ERR%" "!MESSAGE!"
     set "LOAD_FILE=1"
  )
  exit /b

:check_file_lang
if "!LANGUAGE!"=="" set "LANGUAGE=%LOCALE%"
:: Verificar si existe el fichero de idiomas en la ruta especificada, siendo posible /lang/es-ES.txt o /lanb/en-US.txt
set lang_file="%DIR_LANG%\%LANGUAGE%.txt"
if not exist "%lang_file%" (
   call "%DIR_SCRIPT%banner.bat" "%TRYTON%"
   set "MESSAGE=The language file en-US.txt does not exist. Route: %lang_file%"
   if /i "%LANGUAGE%"=="%es-ES%" set "MESSAGE=No existe el fichero de lenguaje es-ES.txt. Ruta: %lang_file%"
   call :logger "%ERR%" "!MESSAGE!"
   set "LOAD_FILE=1"
   exit /b
)
:: Cargamos el fichero de idiomas con eliminación de blancos a la derecha y 20 posibles a la izquierda, saltando la linea de comentario #
for /f "usebackq tokens=1* delims==" %%a in (%lang_file%) do (
    set "key=%%a"
    set "val=%%b"
    if "!key:~0,1!" NEQ "#" (
        :: 1. Left Trim (Elimina espacios a la izquierda)
        for /f "tokens=* delims= " %%i in ("!val!") do set "val=%%i"
        :: 2. Right Trim (Elimina espacios en 20 pasos a la derecha)
        for /l %%j in (1,1,20) do (
            if "!val:~-1!"==" " set "val=!val:~0,-1!"
        )
        if defined val (
          :: Eliminamos caracteres especiales, para evitar problemas con los valores de las key
            set "val=!val:>= !" ^
          & set "val=!val:<= !" ^
          & set "val=!val:|= !" ^
          & set "val=!val:&= !" ^
          & set "val=!val:^= !" ^
          & set "val=!val:%%= !" ^
          & set "val=!val:"= !"
       )
       :: Guardamos la variable 100% limpia
       set "!key!=!val!"
REM    echo "!key!"="!val!"
    )
)
exit /b

:check_service
  set "LOAD_FILE=0"
  if /i "%CURRENT_TRYTON%"=="" set "LOAD_FILE=1"
  if /i "%CURRENT_POSTGRES%"=="" set "LOAD_FILE=1"
  if /i "%CURRENT_CRON%"=="" set "LOAD_FILE=1"
  if /i "%LOAD_FILE%"=="1"  call "%DIR_SCRIPT%checkdocker.bat" %TRYTON%
  set "LOAD_FILE=0"
  exit /b

:check_file_ps1q
  call "%DIR_SCRIPT%banner.bat"  "%TRYTON%"
  set "msg_cont=!WORD_ROUTE! %DIR_HOME%%READ_FILEPS1%"
  set "msg_conc=!WORD_ROUTE! %DIR_HOME%%COMPOSE_FILE%"
  if "%LOAD_FILE%"=="1" set "MESSAGE=!LOG_ERR_PS1! !msg_cont!"
  if "%LOAD_FILE%"=="2" set "MESSAGE=!LOG_ERR_COMPOSE! !msg_conc!"
  if "%LOAD_FILE%"=="3" set "MESSAGE=!LOG_ERR_PS2!"
  if "%LOAD_FILE%"=="4" set "MESSAGE=!LOG_ERR_PS3!"
  set "LOAD_FILE=0"
  call :logger "!LOG-WARN!" "!MESSAGE!"
  echo.
  set "MESSAGE=!LOG_INFO_CONFIRM:PROYECTO=%TRYTON%!"
  :: Solicita confirmación YES por parte del usuario para continuar. 
  set /p "confirm=%BS%        !C_M_GREEN!!MESSAGE!!C_M_RESET! "
  if /i not "%confirm%"=="YES" set "LOAD_FILE=1"
  exit /b

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:exit
  if /i "!EXIT_MSG!" neq "" (
    set "MESSAGE=!EXIT_MSG!"
  ) else (
    set "MESSAGE=Finalizing session. Thank you for using Tryton Manager."
    set "MESSEGE=%MESSEGE% Finalizando sesión. Gracias por utilizar Tryton Docker Manager."
  )
  call "%DIR_SCRIPT%cycletime.bat" "%TIM%" "%time%"
  set "ftime_fmt=%fmt_hhmmss%"
  call "%DIR_SCRIPT%cycletime.bat" "%CALC%" "%itime_tcd%" "%time%"
  set "rtime_fmt=%fmt_hhmmss%"
  set "trydockcmd=%APPLICATION% - %ftime_fmt% !LENG_MSG! %rtime_fmt%"
  echo.
  call :logger "%TXT%" "%trydockcmd%" "3"
  call :logger "%MENU%" "%MESSAGE%" "3"
  call :logger "%MENU%" "!LOG-INFO_WWW!" "3"
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "timeout_start" "!wait_time!" "1" "N"
  cls
  color
  endlocal
  exit /b 0