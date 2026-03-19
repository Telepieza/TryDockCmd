@echo off
:: ===============================================================================
:: PROGRAM:   install.accounts.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      23/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Install accounts (Accounting data) 
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
set "proyecto=%~1"
set "ins_pyth_action=%~2"
set /a "wait_timepyt10=10"
set "log_action=!LOG-INFO!"
set "file_acc_tmp=%DIR_TMP%\trytond_acc"
call "%DIR_SCRIPT%install_header.bat" "%proyecto%" "%ins_pyth_action%" "%PYTH%" "install_accounts"
if %ERRORLEVEL% NEQ 0 goto :exit
:: Si es de install.bat seguimos en el proceso de instalacion
if /i "!ins_pyth_action!"=="%INS%" set "log_action=%INS%"
:: Crear carpeta de logs y tmp si no existe
if not exist "%DIR_LOG%" mkdir "%DIR_LOG%"
if not exist "%DIR_TMP%" mkdir "%DIR_TMP%"
set "temp_file=%file_acc_tmp%_count.txt"
echo.
call :logger "%MENU%" "[+] 1.- !INSTALL_MODU_HEAD44!" "3"
call :logger "%MENU%" "1.1.- !INSTALL_MODU_HEAD46!" "5"
call :logger "%MENU%" "1.2.- !INSTALL_MODU_HEAD47!" "5"
call :logger "%MENU%" "1.3.- !INSTALL_MODU_HEAD50!" "5"
echo.
call :logger "%MENU%" "!INSTALL_MODU_HEAD40!" "3"
echo.
call :logger "%MENU%" "!INSTALL_MODU_HEAD53! %DB_NAME%" "3"
set "iso_code=!TRYTON_LANGUAGE!"
if /i "!iso_code!"=="es" set "iso_code=ES"
if /i "!iso_code!"=="fr" set "iso_code=FR"
if /i "!iso_code!"=="de" set "iso_code=DE"

set "ACCION=ACC"
docker exec -t ^
  -e COMPANY_NAME="!CURRENT_COMPANY_NAME!" ^
  -e COMPANY_CURRENCY="!CURRENT_COMPANY_CURRENCY!" ^
  -e APP_LANGUAGE="!LOCALE!" ^
  !CURRENT_TRYTON! python3 /tmp/auto_full_setup.py !DB_NAME! /tmp/trytond_setup.conf !iso_code! !ACCION!
  if %ERRORLEVEL% GEQ 10 (
    set "MESSAGE=ERROR %ERRORLEVEL%:"
    if %ERRORLEVEL% equ 10 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD55! !DB_NAME!."
    if %ERRORLEVEL% equ 15 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD56! !DB_NAME!."
    if %ERRORLEVEL% equ 40 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD60! [!CURRENT_COMPANY_NAME!]."
    call :logger "!LOG-ERROR!" "!MESSAGE!"
  )

:: 5 Traemos el log actual del contenedor a un temporal para grabar los datos en el pc
set "temp_file=%file_acc_tmp%_!iso_code!.txt"
set "logger_tmp=%DIR_LOG%\%TRYTON%_logger_!iso_code!.log"
set "MESSAGE=!BCK_COPY_CLIENT:ARCHIVO=/tmp/trytond_proteus.txt!"
set "acc_message=!MESSAGE:DESTINO=%logger_tmp%!"
call :logger "%log_action%" "[!ACCION!] !acc_message!" "3"
docker cp !CURRENT_TRYTON!:/tmp/trytond_proteus.txt %temp_file% >nul
if %ERRORLEVEL% EQU 0 (
  echo [!DATE!] [!TIME!] [!ACCION!]  >> "%logger_tmp%"
  type "%temp_file%" >> "%logger_tmp%"
  docker exec -u 0 !CURRENT_TRYTON! rm -f /tmp/trytond_proteus.txt >nul
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "%wait_timepyt10%" "1" "N"
)  
set "ACCOUNTS="
set "cmd=SELECT count(*) FROM account_account;"
call :run_trytond_account "%POSTGRES%" "!cmd!" "%temp_file%"
for /f "usebackq tokens=* delims=" %%i in ("%temp_file%") do set "ACCOUNTS=%%i"
if defined ACCOUNTS call :logger "%log_action%" "!WORD_ACCOUNT_PLAN!: !ACCOUNTS! !WORD_ACCOUNT_CREATE!" "4"

set "FISCALYEARS="
set "cmd=SELECT count(*) FROM account_fiscalyear;"
call :run_trytond_account "%POSTGRES%" "!cmd!" "%temp_file%"
for /f "usebackq tokens=* delims=" %%i in ("%temp_file%") do set "FISCALYEARS=%%i"
if defined FISCALYEARS call :logger "%log_action%" "!WORD_FISCAL_YEARS!: !FISCALYEARS! !WORD_RECORDS!" "4"

set "PERIODS="
set "cmd=SELECT count(*) FROM account_period;"
call :run_trytond_account "%POSTGRES%" "!cmd!" "%temp_file%"
for /f "usebackq tokens=* delims=" %%i in ("%temp_file%") do set "PERIODS=%%i"
if defined PERIODS call :logger "%log_action%" "!WORD_ACCOUNT_PER!: !PERIODS! !WORD_RECORDS!" "4"
 
set "FY_5Y="
set "PERIODS_5Y="
set "cmd=SELECT count(*) FROM account_fiscalyear WHERE name >= '2026';"
call :run_trytond_account "%POSTGRES%" "!cmd!" "%temp_file%"
for /f "usebackq tokens=* delims=" %%i in ("%temp_file%") do set "FY_5Y=%%i"
if defined FY_5Y call :logger "%log_action%" "!WORD_VERIFICATION! 2026-2030: !FY_5Y! !WORD_FISCAL_YEARS!" "4"
set "cmd=SELECT count(*) FROM account_period p JOIN account_fiscalyear f ON f.id = p.fiscalyear WHERE f.name >= '2026';"
call :run_trytond_account "%POSTGRES%" "!cmd!" "%temp_file%"
for /f "usebackq tokens=* delims=" %%i in ("%temp_file%") do set "PERIODS_5Y=%%i"
if defined FY_5Y if defined PERIODS_5Y call :logger "%log_action%" "!WORD_VERIFICATION! 2026-2030: !FY_5Y! !WORD_FISCAL_YEARS!, !PERIODS_5Y! !WORD_PERIODS!" "4"
echo.

set "ACCION=TAX"
docker exec -t ^
  -e COMPANY_NAME="!CURRENT_COMPANY_NAME!" ^
  -e COMPANY_CURRENCY="!CURRENT_COMPANY_CURRENCY!" ^
  -e APP_LANGUAGE="!LOCALE!" ^
  !CURRENT_TRYTON! python3 /tmp/auto_full_setup.py !DB_NAME! /tmp/trytond_setup.conf !iso_code! !ACCION!
  if %ERRORLEVEL% GEQ 10 (
    set "MESSAGE=ERROR %ERRORLEVEL%:"
    if %ERRORLEVEL% equ 10 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD55! !DB_NAME!."
    if %ERRORLEVEL% equ 15 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD56! !DB_NAME!."
    if %ERRORLEVEL% equ 50 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD60! [!CURRENT_COMPANY_NAME!]."
    call :logger "!LOG-ERROR!" "!MESSAGE!"
  )

:: 5 Traemos el log actual del contenedor a un temporal para grabar los datos en el pc
  call :logger "%log_action%" "[!ACCION!] !acc_message!" "3"
  docker cp !CURRENT_TRYTON!:/tmp/trytond_proteus.txt %temp_file% >nul
  if %ERRORLEVEL% EQU 0 (
    echo [!DATE!] [!TIME!] [!ACCION!]  >> "%logger_tmp%"
    type "%temp_file%" >> "%logger_tmp%"
    docker exec -u 0 !CURRENT_TRYTON! rm -f /tmp/trytond_proteus.txt >nul
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "%wait_timepyt10%" "1" "N"
  )

:: Recuperar datos reales de IVA (account_tax) por empresa
set "COMPANY_NAME_SQL=!CURRENT_COMPANY_NAME:'=''!"
set "COMPANY_ID="
set "cmd=SELECT c.id FROM company_company c JOIN party_party p ON p.id = c.party WHERE p.name = '!COMPANY_NAME_SQL!' LIMIT 1;"
call :run_trytond_account "%POSTGRES%" "!cmd!" "%temp_file%"
for /f "usebackq tokens=* delims=" %%i in ("%temp_file%") do set "COMPANY_ID=%%i"

if not defined COMPANY_ID (
  call :logger "%log_action%" "!INSTALL_MODU_HEAD38! [!COMPANY_NAME_SQL!]" "4"
  goto :exit
)

set "TAX_TOTAL="
set "cmd=SELECT count(*) FROM account_tax WHERE company = !COMPANY_ID!;"
call :run_trytond_account "%POSTGRES%" "!cmd!" "%temp_file%"
for /f "usebackq tokens=* delims=" %%i in ("%temp_file%") do set "TAX_TOTAL=%%i"
if defined TAX_TOTAL call :logger "%log_action%" "!WORD_TAXES! (account_tax) !WORD_COMPANY! [!CURRENT_COMPANY_NAME!]: !TAX_TOTAL! !WORD_RECORDS!" "4"

set "TAX_IVA_TOTAL="
set "cmd=SELECT count(*) FROM account_tax WHERE company = !COMPANY_ID! AND name ILIKE ('IVA ' || chr(37));"
call :run_trytond_account "%POSTGRES%" "!cmd!" "%temp_file%"
for /f "usebackq tokens=* delims=" %%i in ("%temp_file%") do set "TAX_IVA_TOTAL=%%i"
if defined TAX_IVA_TOTAL call :logger "%log_action%" "!WORD_IVA! !WORD_TOTAL! (account_tax): !TAX_IVA_TOTAL! !WORD_RECORDS!" "4"

set "TAX_IVA_STD="
set "cmd=SELECT count(*) FROM account_tax WHERE company = !COMPANY_ID! AND name IN (('IVA 21' || chr(37)), ('IVA 10' || chr(37)), ('IVA 4' || chr(37)));"
call :run_trytond_account "%POSTGRES%" "!cmd!" "%temp_file%"
for /f "usebackq tokens=* delims=" %%i in ("%temp_file%") do set "TAX_IVA_STD=%%i"
if defined TAX_IVA_STD call :logger "%log_action%" "!WORD_IVA! 21/10/4 (account_tax): !TAX_IVA_STD! !WORD_RECORDS!" "4"

call :logger "!LOG-SUCC!" "!INSTALL_MODU_END!" "3"

if /i "!ins_pyth_action!"=="%APP%" pause
goto :exit

:run_trytond_account
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

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:exit
  endlocal
  exit /b 0
