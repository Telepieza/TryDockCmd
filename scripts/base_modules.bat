@echo off
:: ===============================================================================
:: PROGRAM:   base_modules
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    [Telepieza - Mariano Vallespín]
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      01/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: modulos basicos de trypton
:: ==============================================================================
set "proyecto=%~1"
set "LX="
set "LL="
:: modulos tryton
if !TRYTON_MODULE_F1! NEQ "" set "C1=!TRYTON_MODULE_F1!"
if !TRYTON_MODULE_F1! EQU "" set "C1=country currency company party bank"
if !TRYTON_MODULE_F2! NEQ "" set "C2=!TRYTON_MODULE_F2!"
if !TRYTON_MODULE_F2! EQU "" set "C2=product stock"
if !TRYTON_MODULE_F3! EQU "" set "C3=!TRYTON_MODULE_F3!"
if !TRYTON_MODULE_F3! NEQ "" set "C3=account account_eu account_product account_invoice account_invoice_stock account_payment account_statement"
if !TRYTON_MODULE_F4! NEQ "" set "C4=!TRYTON_MODULE_F4!"
if !TRYTON_MODULE_F4! EQU "" set "C4=sale purchase"
if !TRYTON_MODULE_F5! NEQ "" set "C5=!TRYTON_MODULE_F5!"
if !TRYTON_MODULE_F5! EQU "" set "C5=stock_supply purchase_request"
if !TRYTON_MODULE_F6! NEQ "" set "C6=!TRYTON_MODULE_F6!"
if !TRYTON_MODULE_F6! EQU "" set "C6=product_image product_attribute product_measurements product_price_list stock_lot"
if !TRYTON_MODULE_F7! NEQ "" set "C7=!TRYTON_MODULE_F7!"
if !TRYTON_MODULE_F7! EQU "" set "C7=production production_routing production_work stock_supply_production project timesheet company_work_time carrier stock_shipment_cost sale_shipment_cost incoterm"
if !TRYTON_MODULE_F8! NEQ "" set "C8=!TRYTON_MODULE_F8!"
if !TRYTON_MODULE_F8! EQU "" set "C8=dashboard marketing party_relationship party_avatar"

set "F1= [1/8] !INSTALL_MODU_PRODC1! (!C1: =, !)"
set "F2= [2/8] !INSTALL_MODU_PRODC2! (!C2: =, !)"
set "F3= [3/8] !INSTALL_MODU_PRODC3! (!C3: =, !)"
set "F4= [4/8] !INSTALL_MODU_PRODC4! (!C4: =, !)"
set "F5= [5/8] !INSTALL_MODU_PRODC5! (!C5: =, !)"
set "F6= [6/8] !INSTALL_MODU_PRODC6! (!C6: =, !)"
set "F7= [7/8] !INSTALL_MODU_PRODC7! (!C7: =, !)"
set "F8= [8/8] !INSTALL_MODU_PRODC8! (!C8: =, !)"

:: rutas localizar los odulos en trytond
if /i "!TRYTON_BASE_IR!" NEQ "" set "BASE_I=!TRYTON_BASE_IR!"
if /i "!TRYTON_BASE_IR!" == "" set "BASE_I=/usr/local/lib/python3.11/dist-packages/trytond/ir"
if /i "!TRYTON_BASE_MODULE!" NEQ "" set "BASE_M=!TRYTON_BASE_MODULE!"
if /i "!TRYTON_BASE_MODULE!" == "" set "BASE_M=/usr/local/lib/python3.11/dist-packages/trytond/modules"
if /i "!TRYTON_BASE_RES!" NEQ "" set "BASE_R=!TRYTON_BASE_RES!"
if /i "!TRYTON_BASE_RES!" == "" set "BASE_R=/usr/local/lib/python3.11/dist-packages/trytond/res"

:: modulos demo
if !TRYTON_MODULE_D1! NEQ "" set "D1=!TRYTON_MODULE_D1!"
if !TRYTON_MODULE_D1! EQU "" set "D1=country currency company party bank"
if !TRYTON_MODULE_D2! NEQ "" set "D2=!TRYTON_MODULE_D2!"
if !TRYTON_MODULE_D2! EQU "" set "D2=product stock"
if !TRYTON_MODULE_D3! EQU "" set "D3=!TRYTON_MODULE_D3!"
if !TRYTON_MODULE_D3! NEQ "" set "D3=account account_payment account_product account_statement account_invoice account_invoice_stock"
if !TRYTON_MODULE_D4! NEQ "" set "D4=!TRYTON_MODULE_D4!"
if !TRYTON_MODULE_D4! EQU "" set "D4=sale purchase"
if !TRYTON_MODULE_D5! NEQ "" set "D5=!TRYTON_MODULE_D5!"
if !TRYTON_MODULE_D5! EQU "" set "D5=production production_work party_avatar company_work_time timesheet"
if !TRYTON_MODULE_D6! NEQ "" set "D6=!TRYTON_MODULE_D6!"
if !TRYTON_MODULE_D6! EQU "" set "D6=project"

set "G1= [1/6] !INSTALL_MODU_DEMOC1! (!D1: =, !)"
set "G2= [2/6] !INSTALL_MODU_DEMOC2! (!D2: =, !)"
set "G3= [3/6] !INSTALL_MODU_DEMOC3! (!D3: =, !)"
set "G4= [4/6] !INSTALL_MODU_DEMOC4! (!D4: =, !)"
set "G5= [5/6] !INSTALL_MODU_PRODC5! (!D5: =, !)"
set "G6= [6/6] !INSTALL_MODU_PRODC6! (!D6: =, !)"

:: Localization (Language)
if !TRYTON_MODULE_ES! NEQ "" set "ES=!TRYTON_MODULE_ES!"
if !TRYTON_MODULE_ES! EQU "" set "ES=account_es account_statement_sepa account_statement_aeb43"
if !TRYTON_MODULE_FR! NEQ "" set "FR=!TRYTON_MODULE_FR!"
if !TRYTON_MODULE_FR! EQU "" set "FR=party_siret account_fr account_fr_chorus account_payment_sepa account_payment_sepa_cfonb"
if !TRYTON_MODULE_DE! NEQ "" set "DE=!TRYTON_MODULE_DE!"
if !TRYTON_MODULE_DE! EQU "" set "DE=account_de_skr03 account_statement_mt940"

set "LS= [1/1] !INSTALL_MODU_LANGES! (!ES: =, !)"
set "LR= [1/1] !INSTALL_MODU_LANGFR! (!FR: =, !)"
set "LE= [1/1] !INSTALL_MODU_LANGDE! (!DE: =, !)"

if /i "!TRYTON_LANGUAGE!" EQU "es"  set "LX=!LS!" & set "LL=!ES!"
if /i "!TRYTON_LANGUAGE!" EQU "fr"  set "LX=!LR!" & set "LL=!FR!"
if /i "!TRYTON_LANGUAGE!" EQU "de"  set "LX=!LE!" & set "LL=!DE!"

exit /b