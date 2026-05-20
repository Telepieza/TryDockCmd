@echo off
:: ===============================================================================
:: PROGRAM:   base_modules
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    Telepieza
:: COLLABORATOR: Gemini Code Assist
:: VERSION:   1.1.30
:: DATE:      20/05/2026
:: LICENSE:   MIT License
:: DESCRIPTION: modulos basicos de trypton version 7 y 8
:: ==============================================================================
set "proyecto=%~1"
set "type=%~2"

call "%DIR_SCRIPT%message.bat" "%APP%" "base_modules %type% [%BASE_MODULES_FILTERED%]"
if "%BASE_MODULES_FILTERED%" EQU "1" exit /b
set "LX="
set "LL="

:: modulos tryton
if "!TRYTON_MODULE_F1!" NEQ "" set "C1=!TRYTON_MODULE_F1!"
if "!TRYTON_MODULE_F1!" EQU "" set "C1=country currency company party bank"
if "!TRYTON_MODULE_F2!" NEQ "" set "C2=!TRYTON_MODULE_F2!"
if "!TRYTON_MODULE_F2!" EQU "" set "C2=product stock"
if "!TRYTON_MODULE_F3!" NEQ "" set "C3=!TRYTON_MODULE_F3!"
if "!TRYTON_MODULE_F3!" EQU "" (
    set "C3=account account_product account_invoice account_invoice_stock account_payment account_statement"
    if "!CURRENT_VERSION:~0,1!"=="7" set "C3=!C3! account_eu"
)
if "!TRYTON_MODULE_F4!" NEQ "" set "C4=!TRYTON_MODULE_F4!"
if "!TRYTON_MODULE_F4!" EQU "" set "C4=sale purchase"
if "!TRYTON_MODULE_F5!" NEQ "" set "C5=!TRYTON_MODULE_F5!"
if "!TRYTON_MODULE_F5!" EQU "" set "C5=stock_supply purchase_request"
if "!TRYTON_MODULE_F6!" NEQ "" set "C6=!TRYTON_MODULE_F6!"
if "!TRYTON_MODULE_F6!" EQU "" set "C6=product_image product_attribute product_measurements product_price_list stock_lot"
if "!TRYTON_MODULE_F7!" NEQ "" set "C7=!TRYTON_MODULE_F7!"
if "!TRYTON_MODULE_F7!" EQU "" set "C7=production production_routing production_work stock_supply_production project timesheet company_work_time carrier stock_shipment_cost sale_shipment_cost incoterm"
if "!TRYTON_MODULE_F8!" NEQ "" set "C8=!TRYTON_MODULE_F8!"
if "!TRYTON_MODULE_F8!" EQU "" set "C8=dashboard marketing party_relationship party_avatar"

set "F1= [1/8] !INSTALL_MODU_PRODC1! (!C1: =, !)"
set "F2= [2/8] !INSTALL_MODU_PRODC2! (!C2: =, !)"
set "F3= [3/8] !INSTALL_MODU_PRODC3! (!C3: =, !)"
set "F4= [4/8] !INSTALL_MODU_PRODC4! (!C4: =, !)"
set "F5= [5/8] !INSTALL_MODU_PRODC5! (!C5: =, !)"
set "F6= [6/8] !INSTALL_MODU_PRODC6! (!C6: =, !)"
set "F7= [7/8] !INSTALL_MODU_PRODC7! (!C7: =, !)"
set "F8= [8/8] !INSTALL_MODU_PRODC8! (!C8: =, !)"

:: Determine Python version based on Tryton version for module paths
set "PYTHON_VERSION_DIR=python3.11"
if "!CURRENT_VERSION:~0,1!"=="8" set "PYTHON_VERSION_DIR=python3.13"
set "BASE_PATH=/usr/local/lib/"!PYTHON_VERSION_DIR!"/dist-packages/trytond"
:: Rutas para localizar los módulos en trytond
if /i "!BASE_I!" EQU "" (
  set "BASE_I=!TRYTON_BASE_IR_V7!"
  if "!CURRENT_VERSION:~0,1!"=="8" set "BASE_I=!TRYTON_BASE_IR_V8!"
  if /i "!BASE_I!" EQU "" set "BASE_I=!BASE_PATH!/ir"
)  
if /i "!BASE_M!" EQU "" (
  set "BASE_M=!TRYTON_BASE_MODULE_V7!"
  if "!CURRENT_VERSION:~0,1!"=="8" set "BASE_M=!TRYTON_BASE_MODULE_V8!"
  if /i "!BASE_M!" EQU "" set "BASE_M=!BASE_PATH!/modules"
)
if /i "!BASE_R!" EQU "" (
  set "BASE_R=!TRYTON_BASE_RES_V7!"
  if "!CURRENT_VERSION:~0,1!"=="8" set "BASE_R=!TRYTON_BASE_RES_V8!"
  if /i "!BASE_R!" EQU "" set "BASE_M=!BASE_PATH!/res"
)

if /i "!TRYTON_BASE_MODULE!" EQU "" set "TRYTON_BASE_MODULE=!BASE_M!"

if "!TRYTON_MODULE_D1!" NEQ "" set "D1=!TRYTON_MODULE_D1!"
if "!TRYTON_MODULE_D1!" EQU "" set "D1=country currency company party bank"
if "!TRYTON_MODULE_D2!" NEQ "" set "D2=!TRYTON_MODULE_D2!"
if "!TRYTON_MODULE_D2!" EQU "" set "D2=product stock"
if "!TRYTON_MODULE_D3!" NEQ "" set "D3=!TRYTON_MODULE_D3!"
if "!TRYTON_MODULE_D3!" EQU "" (
    set "D3=account account_payment account_product account_statement account_invoice account_invoice_stock"
    if "!CURRENT_VERSION:~0,1!"=="7" set "D3=!D3! account_eu"
)
if "!TRYTON_MODULE_D4!" NEQ "" set "D4=!TRYTON_MODULE_D4!"
if "!TRYTON_MODULE_D4!" EQU "" set "D4=sale purchase"
if "!TRYTON_MODULE_D5!" NEQ "" set "D5=!TRYTON_MODULE_D5!"
if "!TRYTON_MODULE_D5!" EQU "" set "D5=production production_work party_avatar company_work_time timesheet"
if "!TRYTON_MODULE_D6!" NEQ "" set "D6=!TRYTON_MODULE_D6!"
if "!TRYTON_MODULE_D6!" EQU "" set "D6=project"

set "G1= [1/6] !INSTALL_MODU_DEMOC1! (!D1: =, !)"
set "G2= [2/6] !INSTALL_MODU_DEMOC2! (!D2: =, !)"
set "G3= [3/6] !INSTALL_MODU_DEMOC3! (!D3: =, !)"
set "G4= [4/6] !INSTALL_MODU_DEMOC4! (!D4: =, !)"
set "G5= [5/6] !INSTALL_MODU_PRODC5! (!D5: =, !)"
set "G6= [6/6] !INSTALL_MODU_PRODC6! (!D6: =, !)"

:: Localization (Language)
:: --- Localization Configuration ---
if "!TRYTON_MODULE_ES!"=="" (set "ES=account_es account_statement_sepa account_statement_aeb43") else (set "ES=!TRYTON_MODULE_ES!")
if "!TRYTON_MODULE_FR!"=="" (set "FR=party_siret account_fr account_fr_chorus account_payment_sepa account_payment_sepa_cfonb") else (set "FR=!TRYTON_MODULE_FR!")
if "!TRYTON_MODULE_DE!"=="" (set "DE=account_de_skr03 account_statement_mt940") else (set "DE=!TRYTON_MODULE_DE!")

:: Filter list based on selected language
if /i "!TRYTON_LANGUAGE!"=="es" (set "LIST=!ES!" & set "L_LABEL=!INSTALL_MODU_LANGES!" & set "LS= [1/1] !INSTALL_MODU_LANGES! (!ES: =, !)")
if /i "!TRYTON_LANGUAGE!"=="fr" (set "LIST=!FR!" & set "L_LABEL=!INSTALL_MODU_LANGFR!" & set "LR= [1/1] !INSTALL_MODU_LANGFR! (!FR: =, !)")
if /i "!TRYTON_LANGUAGE!"=="de" (set "LIST=!DE!" & set "L_LABEL=!INSTALL_MODU_LANGDE!" & set "LE= [1/1] !INSTALL_MODU_LANGDE! (!DE: =, !)")

if not defined LIST goto :noList

set "TRYTON_BRANCH=!CURRENT_VERSION:~0,3!"
set "dir_modules_host=!DIR_MODULES!\!TRYTON_LANGUAGE!\!TRYTON_BRANCH!"

:: Dynamic filtering: Only include modules that exist in the container filesystem
for %%M in (!LIST!) do (
    set "FOUND_M=0"
    :: 1. Comprobar si ya reside en el contenedor (Nativo o Pip)
    docker exec !CURRENT_TRYTON! test -d "!TRYTON_BASE_MODULE!/%%M" >nul 2>&1
    if !errorlevel! EQU 0 set "FOUND_M=1"
    if !FOUND_M! EQU 0 (
        :: Intento vía import de Python (útil para módulos pre-instalados o vía Pip)
        docker exec !CURRENT_TRYTON! python3 -c "import trytond.modules.%%M" >nul 2>&1
        if !errorlevel! EQU 0 set "FOUND_M=1"
    )
    :: 2. Si se encontró en el contenedor, validar que su versión sea compatible
    if !FOUND_M! EQU 1 (
        set "tmp_cfg=%%M_check.cfg"
        call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "get_container_tryton_cfg" "%%M" "!tmp_cfg!"
        if !errorlevel! EQU 0 (
            set "m_ver_c="
            for /f "usebackq tokens=2 delims==" %%V in (`findstr /b "version=" "!tmp_cfg!"`) do (
                set "m_ver_c=%%V"
                set "m_ver_c=!m_ver_c: =!"
            )
            if "!m_ver_c!" NEQ "" if "!m_ver_c:~0,3!" NEQ "!TRYTON_BRANCH!" set "FOUND_M=0"
            if exist "!tmp_cfg!" del "!tmp_cfg!"
        )
    )
    :: 3. Si NO se encontro en el contenedor (o era incompatible), buscar en host para inyectar
    if !FOUND_M! EQU 0 (
        if exist "!dir_modules_host!\%%M" (
            call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "inject_module_from_host" "%%M" "!dir_modules_host!\%%M" "!TRYTON_BRANCH!" "!TRYTON_BASE_MODULE!"
            set "res_inj=!errorlevel!"
            set "m_ver=" & if exist "!DIR_TMP!\inject_ver.txt" set /p m_ver=<"!DIR_TMP!\inject_ver.txt"
            if !res_inj! EQU 0 (
                set "FOUND_M=1"
                call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!WORD_MODULE! !WORD_HOST! '%%M' (!m_ver!) !INSTALL_MODU_PAQMS5!."
            ) else if !res_inj! EQU 2 (
                call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!WORD_MODULE! !WORD_HOST! '%%M' (!m_ver!) !INSTALL_MODU_PAQER3! !TRYTON_BRANCH!."
            )
        )
    )
    if !FOUND_M! EQU 1 set "LL=!LL! %%M"
)

:: Final labels for the menu and command
if defined LL (
    for /f "tokens=* delims= " %%i in ("!LL!") do set "LL=%%i"
    set "LX= [1/1] !L_LABEL! (!LL: =, !)"
)

:noList
  set "BASE_MODULES_FILTERED=1"
  set "BASE_MODULES_LANG=!TRYTON_LANGUAGE!"

exit /b