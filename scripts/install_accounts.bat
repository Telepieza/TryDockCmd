@echo off
:: ===============================================================================
:: PROGRAM:   install.accounts.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    [Telepieza - Mariano Vallespín]
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      01/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Install accounts (Accounting data) 
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
set "proyecto=%~1"
set "ins_pyth_action=%~2"
set /a "wait_timepyt10=10"
set /a "wait_timepyt5=5"
set "log_action=!LOG-INFO!"
call "%DIR_SCRIPT%install_header.bat" "%proyecto%" "%ins_pyth_action%" "%PYTH%" "install_accounts"
if %ERRORLEVEL% NEQ 0 goto :exit
:: Si es de install.bat seguimos en el proceso de instalacion
if /i "!ins_pyth_action!"=="%INS%" set "log_action=%INS%"
:: Crear carpeta de logs y tmp si no existe
if not exist "%DIR_LOG%" mkdir "%DIR_LOG%"
if not exist "%DIR_TMP%" mkdir "%DIR_TMP%"
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
  
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt10!" "1"

: Recuperar datos reales mediante SQL rápido
for /f "tokens=*" %%i in ('docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U postgres -d %DB_NAME% -At -c "SELECT count(*) FROM account_account;"') do set ACCOUNTS=%%i
for /f "tokens=*" %%i in ('docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U postgres -d %DB_NAME% -At -c "SELECT count(*) FROM account_fiscalyear;"') do set FISCALYEARS=%%i
for /f "tokens=*" %%i in ('docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U postgres -d %DB_NAME% -At -c "SELECT count(*) FROM account_period;"') do set PERIODS=%%i
for /f "tokens=*" %%i in ('docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U postgres -d %DB_NAME% -At -c "SELECT count(*) FROM account_fiscalyear WHERE name >= ''2026'';"') do set FY_5Y=%%i
for /f "tokens=*" %%i in ('docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U postgres -d %DB_NAME% -At -c "SELECT count(*) FROM account_period p JOIN account_fiscalyear f ON f.id = p.fiscalyear WHERE f.name >= ''2026'';"') do set PERIODS_5Y=%%i
call :logger "%log_action%" "!WORD_ACCOUNT_PLAN!: !ACCOUNTS! !WORD_ACCOUNT_CREATE!" "4"
call :logger "%log_action%" "!WORD_FISCAL_YEARS!: !FISCALYEARS! !WORD_RECORDS!" "4"
call :logger "%log_action%" "!WORD_ACCOUNT_PER!: !PERIODS! !WORD_RECORDS!" "4"
call :logger "%log_action%" "!WORD_VERIFICATION! 2026-2030: !FY_5Y! !WORD_FISCAL_YEARS!, !PERIODS_5Y! !WORD_PERIODS!" "4"
echo.
:: 4. Mantenemos tu rutina de espera si lo deseas, aunque 'exec' es síncrono
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt10!" "1"
call :logger "!LOG-SUCC!" "!INSTALL_MODU_END!" "3"
echo.
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt10!" "1"
if /i "!ins_pyth_action!"=="%APP%" pause
goto :exit

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:exit
  endlocal
  exit /b 0
