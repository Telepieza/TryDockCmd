@echo off
:: ===============================================================================
:: PROGRAM:   install.python.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    [Telepieza - Mariano Vallespín]
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      01/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Install python 
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
set "proyecto=%~1"
set "ins_pyth_action=%~2"
set /a "wait_timepyt10=10"
set /a "wait_timepyt5=5"
set "log_action=!LOG-INFO!"
call "%DIR_SCRIPT%install_header.bat" "%proyecto%" "%ins_pyth_action%" "%PYTH%" "install_python"
if %ERRORLEVEL% NEQ 0 goto :exit
:: Si es de install.bat seguimos en el proceso de instalacion
if /i "!ins_pyth_action!"=="%INS%" set "log_action=%INS%"
:: Crear carpeta de logs y tmp si no existe
if not exist "%DIR_LOG%" mkdir "%DIR_LOG%"
if not exist "%DIR_TMP%" mkdir "%DIR_TMP%"

call :logger "%INS%" "[1/1] !INSTALL_MODU_HEAD44!" "3"
call :logger "%INS%" "[1.1] !BCK_FILE_ZIP! %DIR_TMP%\tmp\trytond_proteus.txt!" "5"
call :logger "%INS%" "[1.2] !INSTALL_MODU_HEAD45!" "5"
call :logger "%INS%" "[1.3] !INSTALL_MODU_HEAD46!" "5"
call :logger "%INS%" "[1.4] !INSTALL_MODU_HEAD47!" "5"
call :logger "%INS%" "[1.5] !INSTALL_MODU_HEAD48!" "5"
call :logger "%INS%" "[1.6] !INSTALL_MODU_HEAD49!" "5"
call :logger "%INS%" "[1.7] !INSTALL_MODU_HEAD50!" "5"


call :logger "%log_action%" "!INSTALL_MODU_HEAD54! !TRYTON_LANGUAGE!" "3"
set "iso_code=!TRYTON_LANGUAGE!"
if /i "!iso_code!"=="es" set "iso_code=ES"
if /i "!iso_code!"=="fr" set "iso_code=FR"
if /i "!iso_code!"=="de" set "iso_code=DE"
set "ACCION=LANG"
:: Ejecuta la inyección combinada
docker exec -t ^
  -e COMPANY_NAME="!CURRENT_COMPANY_NAME!" ^
  -e COMPANY_CURRENCY="!CURRENT_COMPANY_CURRENCY!" ^
  -e APP_LANGUAGE="!LOCALE!" ^
  !CURRENT_TRYTON! python3 /tmp/auto_full_setup.py !DB_NAME! /tmp/trytond_setup.conf !iso_code! !ACCION!
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt10!" "1"
  if %ERRORLEVEL% GEQ 10 (
    set "MESSAGE=ERROR %ERRORLEVEL%:"
    if %ERRORLEVEL% equ 10 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD55! !DB_NAME!."
    if %ERRORLEVEL% equ 15 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD56! !DB_NAME!."
    if %ERRORLEVEL% equ 30 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD59! [!LOCALE!]"
    call :logger "!LOG-ERROR!" "!MESSAGE!"
  )
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt10!" "1"

  set "ACCION=ACC"
:: Ejecuta la inyección combinada
docker exec -t ^
  -e COMPANY_NAME="!CURRENT_COMPANY_NAME!" ^
  -e COMPANY_CURRENCY="!CURRENT_COMPANY_CURRENCY!" ^
  -e APP_LANGUAGE="!LOCALE!" ^
  !CURRENT_TRYTON! python3 /tmp/auto_full_setup.py !DB_NAME! /tmp/trytond_setup.conf !iso_code! !ACCION!
  if %ERRORLEVEL% GEQ 10 (
    set "MESSAGE=ERROR %ERRORLEVEL%:"
    if %ERRORLEVEL% equ 10 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD55! !DB_NAME!."
    if %ERRORLEVEL% equ 15 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD56! !DB_NAME!."
    if %ERRORLEVEL% equ 40 set "MESSAGE=!MESSAGE! !INSTALL_MODU_HEAD60! [!CURRENT_COMPANY_NAME!]"
    call :logger "!LOG-ERROR!" "!MESSAGE!"
  )

  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt10!" "1"

:: --- BLOQUE DE RESUMEN FINAL ---
if %ERR_CODE% equ 0 (
    call message.bat LOG-SUCC "======================================================"
    call message.bat LOG-SUCC "   DESPLIEGE DE TRYTON COMPLETADO CON ÉXITO"
    call message.bat LOG-SUCC "======================================================"
    :: Recuperar datos reales mediante SQL rápido
    for /f "tokens=*" %%i in ('docker exec -t tryton-postgres psql -U tryton -d tryton -t -c "SELECT count(*) FROM account_account;"') do set ACCOUNTS=%%i
    for /f "tokens=*" %%i in ('docker exec -t tryton-postgres psql -U tryton -d tryton -t -c "SELECT count(*) FROM ir_lang WHERE translatable=true;"') do set LANGUAGES=%%i
    :: Visualizar con tu sistema de mensajes (Usando el parámetro de espacio %~3)
    call message.bat LOG-INFO "Resumen del Sistema:"
    call message.bat TXT "Plan Contable: !ACCOUNTS! cuentas creadas" 4
    call message.bat TXT "Idiomas Activos: !LANGUAGES! configurados" 4
    call message.bat TXT "Base de Datos: %DB_NAME%" 4
    call message.bat LOG-SUCC "------------------------------------------------------"
    call message.bat LOG-INFO "Estado: LISTO PARA PRODUCCIÓN"
)

pause

:: 3. Limpiamos el rastro
:: docker exec -t !CURRENT_TRYTON! rm /tmp/auto_full_setup.py

:: 4. Mantenemos tu rutina de espera si lo deseas, aunque 'exec' es síncrono
call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timepyt10!" "1"

call :logger "!LOG-SUCC!" "!INSTALL_MODU_END!" "3"
echo.
goto :exit

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:exit
  endlocal
  exit /b 0
