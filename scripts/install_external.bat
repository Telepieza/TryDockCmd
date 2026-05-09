@echo off
:: ===============================================================================
:: PROGRAM:   install.external.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    https://www.telepieza.com
:: COLLABORATOR: Gemini Code Assist
:: VERSION:   1.1.26
:: DATE:      10/05/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Install trytond tryton version 7 y 8
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: Analiza si la llamada es del tcd.bat
set "proyecto=%~1"
set "ins_exter_action=%~2"
set "file_impre=%~3"
set /a "wait_timemodex=10"
set /a "numer_ext=0"

:: Inicializar fichero temporal para el árbol de dependencias
set "file_deps_tree=%DIR_TMP%\deps_tree.txt"
if exist "!file_deps_tree!" del "!file_deps_tree!"

:: Asegurar que las variables de rutas de módulos (TRYTON_BASE_MODULE) están cargadas
if "!TRYTON_BASE_MODULE!"=="" call "%DIR_SCRIPT%base_modules.bat" "%proyecto%" "%ins_exter_action%"

set "COM1=TRYTOND_DATABASE_URI=!DB_URI! trytond-admin -c /etc/trytond.conf -d !DB_NAME!" 
set "COM2=TRYTONPASSFILE=/tmp/.passwd"
set "COM3= --email !EMAIL! -vv"

if /i "!TRYTON_LANGUAGE!" EQU "es" (
  :: Asegurar dependencias de Python para la localización española (signxml para Facturae/Verifactu)
  set "NEEDS_CRYPTO=NO"
  if /i "!TRYTON_MODULE_ES_FACTURAE!" EQU "YES" set "NEEDS_CRYPTO=YES"
  if /i "!TRYTON_MODULE_ES_VERIFACTU!" EQU "YES" set "NEEDS_CRYPTO=YES"

  if "!NEEDS_CRYPTO!" EQU "YES" (
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "install_python_deps" "signxml" "libxmlsec1-dev pkg-config"
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "install_python_deps" "pyOpenSSL"
  )

  :: Estrategia de búsqueda multi-proveedor (NaN-tic, Comunidad Heptapod)
  set "TRYTON_BRANCH=!CURRENT_VERSION:~0,3!"
  set "PROVIDERS=COMMUNITY NANTIC"

  :: Validar si la versión está en el rango soportado
  set "VER_OK=NO"
  for %%V in (7.2 7.4 7.6 7.8 8.0) do if "!TRYTON_BRANCH!"=="%%V" set "VER_OK=YES"

  if "!VER_OK!"=="YES" call :resolve_all_dependencies

  :: Sincronizar la lista de módulos para que Tryton reconozca los paquetes instalados por Pip/Git
  call :update_modules_trytond

  if /i "!TRYTON_MODULE_ES_VERIFACTU!" EQU "YES" if /i "!TRYTON_MODULE_ES_SII!"=="YES" set "TRYTON_MODULE_ES_SII=NO"
  if /i "!TRYTON_MODULE_ES_VERIFACTU!" EQU "YES" call :install_module_external "account_es_verifactu" "account_es_verifactu"
  if /i "!TRYTON_MODULE_ES_SII!" EQU "YES" call :install_module_external "account_es_sii" "account_es_sii"
  if /i "!TRYTON_MODULE_ES_FACTURAE!" EQU "YES" call :install_module_external "account_invoice_facturae" "account_invoice_facturae edocument_es_facturae"
)

if /i "!TRYTON_LANGUAGE!" EQU "de" (
  if /i "!TRYTON_MODULE_DE_SKR03!" EQU "YES" call :install_module_external "account_de_skr03" "account_de_skr03"
)

goto :exit

:: Subrutina de Resolución Dinámica (Evita errores de etiquetas en bloques IF)
:resolve_all_dependencies
  :: 1. Inicializar la cola con los módulos raíz seleccionados
  set "MODS_QUEUE= "
  if "!TRYTON_BRANCH!"=="8.0" set "MODS_QUEUE=!MODS_QUEUE! account_es "
  if /i "!TRYTON_MODULE_ES_FACTURAE!" EQU "YES" set "MODS_QUEUE=!MODS_QUEUE! account_invoice_facturae "
  if /i "!TRYTON_MODULE_ES_VERIFACTU!" EQU "YES" set "MODS_QUEUE=!MODS_QUEUE! account_es_verifactu "
  if /i "!TRYTON_MODULE_ES_SII!" EQU "YES" set "MODS_QUEUE=!MODS_QUEUE! account_es_sii "
  set "MODS_QUEUE=!MODS_QUEUE! account_es_aeat "
  
  set "MODS_HANDLED= "

  :process_queue
  if "!MODS_QUEUE!"==" " goto :queue_done

  :: Extraer el primer módulo de la cola
  for /f "tokens=1*" %%a in ("!MODS_QUEUE!") do (
      set "M_NAME=%%a"
      set "MODS_QUEUE= %%b"
      if "!MODS_QUEUE!"=="" set "MODS_QUEUE= "
      set "M_TYPE=EXTERNO"
  )
  if "!M_NAME!"=="" goto :process_queue

  :: Evitar procesar lo mismo varias veces
  echo !MODS_HANDLED! | findstr /i " !M_NAME! " >nul
  if !errorlevel! EQU 0 goto :process_queue
  set "MODS_HANDLED=!MODS_HANDLED!!M_NAME! "

  set "REPO_ALIAS_NANTIC=trytond-!M_NAME!"
  :: Sección de Alias: Mapear nombre del módulo con nombre real del repositorio en GitHub
  if "!M_NAME!"=="account_es_verifactu" set "REPO_ALIAS_NANTIC=trytond-aeat_verifactu"
  if "!M_NAME!"=="aeat_party_validation" set "REPO_ALIAS_NANTIC=trytond-aeat_party_validation"
  if "!M_NAME!"=="certificate_manager" set "REPO_ALIAS_NANTIC=trytond-certificate_manager"
  if "!M_NAME!"=="account_invoice_company_currency" set "REPO_ALIAS_NANTIC=trytond-account_invoice_company_currency"
  if "!M_NAME!"=="account_invoice_vat_required" set "REPO_ALIAS_NANTIC=trytond-account_invoice_vat_required"

  set "LOCATED=NO"
  set "IS_NATIVE=NO"

  :: 1. Verificar si el módulo ya está registrado en Tryton (Nativo o pre-instalado)
  for /f "usebackq" %%a in (`docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U "%POSTGRES%" -d "!DB_NAME!" -At -c "SELECT count(*) FROM ir_module WHERE name='!M_NAME!';" 2^>nul`) do set "db_exists=%%a"
  if "!db_exists!"=="1" (
      set "LOCATED=YES"
      set "IS_NATIVE=YES"
      set "M_TYPE=NATIVO"
  )

  :: 2. Si no está en DB, verificar existencia física o en Python (Copiado manualmente o instalado)
  if "!LOCATED!"=="NO" (
      docker exec -u 0 "!CURRENT_TRYTON!" test -d "!TRYTON_BASE_MODULE!/!M_NAME!" >nul 2>&1
      if !errorlevel! EQU 0 (
          set "LOCATED=YES"
      ) else (
          docker exec -u 0 "!CURRENT_TRYTON!" python3 -c "import trytond.modules.!M_NAME!" >nul 2>&1
          if !errorlevel! EQU 0 set "LOCATED=YES"
      )
  )

  if "!LOCATED!"=="YES" (
      if "!IS_NATIVE!"=="YES" (
          call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!WORD_MODULE! !M_NAME! detectado como módulo NATIVO."
      ) else (
          call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!WORD_MODULE! !M_NAME! ya presente en el sistema."
      )
  )

  :: 3. Bucle de proveedores para cada módulo
  if "!LOCATED!"=="NO" (
      for %%P in (!PROVIDERS!) do (
          if "!LOCATED!"=="NO" call :get_from_%%P "!M_NAME!" "!TRYTON_BRANCH!" "!REPO_ALIAS_NANTIC!"
      )
  )
  
  :: 4. Análisis dinámico de dependencias
  if "!LOCATED!"=="YES" (
      if "!IS_NATIVE!"=="YES" goto :skip_analysis

      set "tmp_cfg=%TEMP%\!M_NAME!_tryton.cfg"
      set "tmp_deps=%TEMP%\!M_NAME!_deps.txt"
      call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "get_container_tryton_cfg" "!M_NAME!" "!tmp_cfg!"
      if !errorlevel! EQU 0 (
          call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "get_module_dependencies" "!tmp_cfg!" "!tmp_deps!"
          if exist "!tmp_deps!" (
              for /f "usebackq tokens=*" %%D in ("!tmp_deps!") do (
                  set "DEP_NAME=%%D"
                  echo [!M_TYPE!] !M_NAME! ^|^|-- !DEP_NAME! >> "!file_deps_tree!"
                  echo !MODS_HANDLED! | findstr /i " !DEP_NAME! " >nul
                  if !errorlevel! NEQ 0 (
                      echo !MODS_QUEUE! | findstr /i " !DEP_NAME! " >nul
                      if !errorlevel! NEQ 0 set "MODS_QUEUE=!MODS_QUEUE!!DEP_NAME! "
                  )
              )
          )
      )
  )
  :skip_analysis
  if "!LOCATED!"=="NO" (
      if "!M_NAME!"=="account_es" if "!TRYTON_BRANCH!"=="8.0" (
          call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "¡CRITICO! No se localizó account_es para 8.0. La localización española no funcionará."
      )
  )
  goto :process_queue
  :queue_done
  call "%DIR_SCRIPT%install_reports.bat" "%proyecto%" "10" "" "ARBOL DE DEPENDENCIAS RESUELTO" "3" "!file_deps_tree!"
  exit /b

:: Subrutina para buscar en la Comunidad (Heptapod)
:get_from_COMMUNITY
  set "m_target=%~1"
  set "b_target=%~2"
  set "R_URL=https://foss.heptapod.net/tryton-community/modules/!m_target!"
  :: Primero miramos si 'default' es compatible via tryton.cfg
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "check_remote_tryton_cfg" "!R_URL!" "!b_target!"
  if !errorlevel! EQU 0 (
      call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "install_python_deps" "git+!R_URL!.git@default#egg=trytond_!m_target!" "" "trytond.modules.!m_target!"
      set "LOCATED=YES"
      :: Registro de auditoría
      call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "get_git_remote_hash" "!R_URL!.git" "default"
      if !errorlevel! EQU 0 (
          set /p g_hash=<"%TEMP%\git_hash.txt"
          (echo [!DATE! !TIME!] MODULE:!m_target! PROVIDER:COMMUNITY BRANCH:default HASH:!g_hash!) >> "%DIR_LOG%\modules_git_audit.log"
      )
      exit /b 0
  )
  :: Si no, miramos si existe la rama de la versión
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "check_git_branch_exists" "!R_URL!.git" "!b_target!"
  if !errorlevel! EQU 0 (
      call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "install_python_deps" "git+!R_URL!.git@!b_target!#egg=trytond_!m_target!" "" "trytond.modules.!m_target!"
      set "LOCATED=YES"
      call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "get_git_remote_hash" "!R_URL!.git" "!b_target!"
      if !errorlevel! EQU 0 (
          set /p g_hash=<"%TEMP%\git_hash.txt"
          (echo [!DATE! !TIME!] MODULE:!m_target! PROVIDER:COMMUNITY BRANCH:!b_target! HASH:!g_hash!) >> "%DIR_LOG%\modules_git_audit.log"
      )
  )
  exit /b 0

:: Subrutina para buscar en NaN-tic (GitHub)
:get_from_NANTIC
  set "m_target=%~1"
  set "b_target=%~2"
  set "repo_alias=%~3"
  if "!repo_alias!"=="" set "repo_alias=trytond-!m_target!"
  :: Construir el nombre del EGG siguiendo el estándar de NaN-tic (nantic-trytond-modulo)
  set "m_egg=!m_target:_=-!"
  set "egg_name=nantic-trytond-!m_egg!"
  set "R_URL=https://github.com/NaN-tic/!repo_alias!.git"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "check_git_branch_exists" "!R_URL!" "!b_target!"
  if !errorlevel! EQU 0 (
      call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "install_python_deps" "git+!R_URL!@!b_target!#egg=!egg_name!" "" "trytond.modules.!m_target!"
      set "LOCATED=YES"
      call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "get_git_remote_hash" "!R_URL!" "!b_target!"
      if !errorlevel! EQU 0 (
          set /p g_hash=<"%TEMP%\git_hash.txt"
          (echo [!DATE! !TIME!] MODULE:!m_target! PROVIDER:NANTIC BRANCH:!b_target! HASH:!g_hash!) >> "%DIR_LOG%\modules_git_audit.log"
      )
  )
  exit /b 0

:install_module_external
  set "EXTERNAL_SQL=%~1"
  set "EXTERNAL_MODULE=%~2"
  set "state_veri="
  set /a numer_ext+=1
  echo "PASO 01" "[%numer_ext%] !INSTALL_MODU_HEAD75! %EXTERNAL_MODULE%"
  call :logger "%ins_exter_action%" "[%numer_ext%] !INSTALL_MODU_HEAD75! %EXTERNAL_MODULE%" "8"
  for /f "usebackq" %%a in (`docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U "%POSTGRES%" -d "!DB_NAME!" -At -c "SELECT state FROM ir_module WHERE name='!EXTERNAL_SQL!';" 2^>nul`) do set "state_veri=%%a"
  if %ERRORLEVEL% NEQ 0  exit /b
  if /i "!state_veri!"=="activated" exit /b
  set "FEX= !INSTALL_MODU_EXTERNAL! (!EXTERNAL_MODULE: =, !)"
  call :logger "%ins_exter_action%" "[%numer_ext%] !INSTALL_MODU_HEAD76! !FEX!" "8"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timemodex!" "1" 
  set "cmd=!COM2! !COM1! -u !EXTERNAL_MODULE! --activate-dependencies !COM3!"
  echo "PASO 02" "[%numer_ext%] !cmd!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%SERVER%" "!cmd!" "!DB_NAME!" "" "%file_impre%" "YES" "" ""
  call :update_modules_trytond
  exit /b

:update_modules_trytond
  call :logger "%ins_exter_action%" "!INSTALL_MODU_HEAD34!" "3"
  set "cmd=!COM2! !COM1! --update-modules-list !COM3!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%SERVER%" "!cmd!" "!DB_NAME!" "" "%file_impre%" "YES" "" ""
  call :logger "%ins_exter_action%" "!INSTALL_MODU_HEAD34_ALL!" "3"
  set "cmd=!COM2! !COM1! --all !COM3!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%SERVER%" "!cmd!" "!DB_NAME!" "" "%file_impre%" "YES" "" ""
  exit /b


:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:exit
  endlocal
  exit /b 0
