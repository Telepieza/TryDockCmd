@echo off
:: ===============================================================================
:: PROGRAM:   install.external.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    https://www.telepieza.com
:: COLLABORATOR: Gemini Code Assist
:: VERSION:   1.1.30
:: DATE:      20/05/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Install trytond tryton version 7 y 8
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: Analiza si la llamada es del tcd.bat
set "proyecto=%~1"
set "module_name=%~2"
set "exter_action=%~3"
set "file_logger=%~4" 
set /a "wait_timemodex=10"
set "IS_NANTIC_ES=NO"
set /a "numer_ext=0"
set "INS_MODULE="

set "ins_exter_action=!LOG-INFO!"
if /i "%exter_action%"=="%INS%"  set "ins_exter_action=%INS%"

call :logger "!ins_exter_action!" "install_external !ins_exter_action! [!file_logger!]" 

:: Inicializar fichero temporal para el árbol de dependencias
set "file_deps_tree=%DIR_TMP%\deps_tree.txt"
if exist "!file_deps_tree!" del "!file_deps_tree!"
:: Asegurar que las variables de rutas de módulos (TRYTON_BASE_MODULE) están cargadas
if /i "!TRYTON_BASE_MODULE!"=="" (
    set "BASE_MODULES_FILTERED=0"
    call "%DIR_SCRIPT%base_modules.bat" "%proyecto%" "!ins_exter_action!"
)

set "COM1=TRYTOND_DATABASE_URI=!DB_URI! trytond-admin -c /etc/trytond.conf -d !DB_NAME! "
set "COM2=TRYTONPASSFILE=/tmp/.passwd"
set "COM3= --email !EMAIL! -vv"

  :: Estrategia de búsqueda multi-proveedor (NaN-tic, Comunidad Heptapod)
  set "TRYTON_BRANCH=!CURRENT_VERSION:~0,3!"
  set "PROVIDERS=!TRYTON_MODULE_PROVIDERS!"
  if /i "!PROVIDERS!"=="" set "PROVIDERS=COMMUNITY TRYDOCKCMD NANTIC"

  :: Lógica de compatibilidad por PREFIX (Solución Brillante):
  :: Para flujos españoles, validamos que el partner coincida con la contabilidad base instalada.
  docker exec -u 0 "!CURRENT_TRYTON!" test -d "!TRYTON_BASE_MODULE!/account_es" >nul 2>&1
  if !errorlevel! EQU 0 (
    docker exec -u 0 "!CURRENT_TRYTON!" grep -qi "PREFIX.*'nantic'" !TRYTON_BASE_MODULE!/account_es/setup.py >nul 2>&1
    if !errorlevel! EQU 0 set "IS_NANTIC_ES=YES"
    if "!IS_NANTIC_ES!"=="NO" (
        :: Si la contabilidad base no es de Nantic, bloqueamos a NANTIC como proveedor para evitar conflictos con los modulos instalados
        set "PROVIDERS=!PROVIDERS:NANTIC=!"
        call "%DIR_SCRIPT%message.bat" "!ins_exter_action!" "!INSTALL_MODU_HEAD82!"
    )
  )

  :: Ciclo de vida Tryton: .0 (LTS 5 años), Pares (Release 9 meses), Impares (Test/Dev)
  set "LIST_VERSIONS=!TRYTON_MODULE_VERSIONS!"
  if /i "!LIST_VERSIONS!"=="" set "LIST_VERSIONS=7.0 7.2 7.4 7.6 7.8 8.0"
  :: Validar si la versión está en el rango soportado
  set "VER_OK=NO" 
  for %%V in (!LIST_VERSIONS!) do if "!TRYTON_BRANCH!"=="%%V" set "VER_OK=YES"
  
  :: Determinar el conjunto de módulos a procesar (module_select) antes de resolver dependencias
  set "module_select="
  if /i "!module_name!" EQU "account_es_verifactu"   set "module_select=!TRYTON_MODULE_ES_VERIFACTU!"   & if "!module_select!"=="" set "module_select=!module_name!"
  if /i "!module_name!" EQU "account_es_sii"         set "module_select=!TRYTON_MODULE_ES_SII!"         & if "!module_select!"=="" set "module_select=!module_name!"
  if /i "!module_name!" EQU "account_es_facturae"    set "module_select=!TRYTON_MODULE_ES_FACTURAE!"    & if "!module_select!"=="" set "module_select=!module_name! edocument_es_facturae"
  if /i "!module_name!" EQU "account_de_skr03"       set "module_select=!TRYTON_MODULE_DE_SKR03!"       & if "!module_select!"=="" set "module_select=!module_name!"
  if "!module_select!"=="" set "module_select=!module_name!"

  :: Instalar signxml

  call "%DIR_SCRIPT%message.bat" "!ins_exter_action!" "!INSTALL_MODU_PAQU03T!"
  if "!VER_OK!"=="YES" (
     call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "install_python_deps" "signxml" "libxmlsec1-dev pkg-config"
     if !errorlevel! NEQ 0  call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_PAQER1!" & goto :exit
  )
  :: Llamada limpia sin paréntesis para evitar errores de parser

  if "!VER_OK!"=="YES" (
    call :resolve_all_dependencies
    if "!INS_MODULE!"=="YES" (
       call :install_module_external "!module_name!" "!module_select!"
       call :update_modules_trytond
       call :stop_start_trytond
    )
  )
goto :exit

:: Subrutina de Resolución Dinámica (Evita errores de etiquetas en bloques IF)
:resolve_all_dependencies
  :: 1. Inicializar la cola con los módulos raíz seleccionados
  set "MODS_QUEUE= "
  if "!CURRENT_VERSION:~0,1!"=="8" set "MODS_QUEUE=!MODS_QUEUE! account_es "
  :: Definir listas de dependencias críticas por flujo (Facturae, SII, Verifactu)
  :: Esto permite gestionar de forma clara y cómoda qué módulos adicionales necesita cada entrada
  set "DEPS_FACTURAE=account_es_aeat account_common account_invoice_shipment account_invoice_discount party_tradename stock_origin stock_origin_sale account_payment_type certificate_manager account_es_facturae"
  set "DEPS_AEAT=account_es_aeat account_payment_type certificate_manager"
  set "MODS_QUEUE=!MODS_QUEUE! !module_select! "
  :: Solo añadir dependencias específicas de Nantic si se detectó su localización contable.
  if "!IS_NANTIC_ES!"=="YES" (
      if /i "!module_name!" EQU "account_es_facturae"   set "MODS_QUEUE=!MODS_QUEUE! !DEPS_FACTURAE! "
      if /i "!module_name!" EQU "account_es_verifactu"  set "MODS_QUEUE=!MODS_QUEUE! !DEPS_AEAT! "
      if /i "!module_name!" EQU "account_es_sii"        set "MODS_QUEUE=!MODS_QUEUE! !DEPS_AEAT! "
  )

  set "MODS_HANDLED= "

  :process_queue
  if "!MODS_QUEUE!"==" " goto :queue_done
  :: Extraer el primer módulo de la cola
  for /f "tokens=1*" %%a in ("!MODS_QUEUE!") do (
      set "M_NAME=%%a"
      set "MODS_QUEUE= %%b"
      if "!MODS_QUEUE!"=="" set "MODS_QUEUE= "
      set "M_TYPE=!WORD_EXTERNAL!"
  )
  if "!M_NAME!"=="" goto :process_queue

  :: Evitar procesar lo mismo varias veces
  echo !MODS_HANDLED! | findstr /i " !M_NAME! " >nul
  if !errorlevel! EQU 0 goto :process_queue
  set "MODS_HANDLED=!MODS_HANDLED!!M_NAME! "

  :: 2. Configuración de Identidad y Mapeos para NANTIC
  if "!IS_NANTIC_ES!"=="YES" (
    call :get_NANTIC_identity
    call :check_NANTIC_pure
  )

  set "LOCATED=NO"
  set "IS_NATIVE=NO"
  set "db_exists=0"
  :: 1. Verificar si el módulo ya está registrado en Tryton (Nativo o pre-instalado)
  for /f "usebackq" %%a in (`docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U "%POSTGRES%" -d "!DB_NAME!" -At -c "SELECT count(*) FROM ir_module WHERE name='!M_NAME!';" 2^>nul`) do set "db_exists=%%a"
  if "!db_exists!"=="1" (
      set "LOCATED=YES"
      set "IS_NATIVE=YES"
      set "M_TYPE=!WORD_NATIVE!"
  )

  :: 2. Si no está en DB, verificar existencia física o en Python (Copiado manualmente o instalado)
  if "!LOCATED!"=="NO" (
      docker exec -u 0 "!CURRENT_TRYTON!" test -d "!TRYTON_BASE_MODULE!/!M_NAME!" >nul 2>&1
      if !errorlevel! EQU 0 (
          set "LOCATED=YES"
      ) else (
          docker exec -u 0 "!CURRENT_TRYTON!" python3 -W ignore -c "import trytond.modules.!M_IMPORT!" >nul 2>&1
          if !errorlevel! EQU 0 set "LOCATED=YES"
      )
  )

  if "!LOCATED!"=="YES" (
      if "!IS_NATIVE!"=="YES" (
          call "%DIR_SCRIPT%message.bat" "!ins_exter_action!" "!WORD_MODULE! !M_NAME! !INSTALL_MODU_PAQMS7!"
      ) else (
          call "%DIR_SCRIPT%message.bat" "!ins_exter_action!" "!WORD_MODULE! !M_NAME! !INSTALL_MODU_PAQMS2!."
      )
  )

  :: Se valida compatibilidad más abajo, después del bucle de proveedores para cubrir nuevas instalaciones
  :: 3. Bucle de proveedores para cada módulo
  if "!LOCATED!"=="NO" (
      :: Detectar si es un módulo que no soporta Pip (Pure Module) en NaN-tic
      for %%P in (!PROVIDERS!) do (
          if "!LOCATED!"=="NO" (
              if /i "%%P"=="COMMUNITY" (
                  call :get_from_COMMUNITY "!M_NAME!" "!CURRENT_VERSION!"
              ) else if /i "%%P"=="TRYDOCKCMD" (
                  call :get_from_TRYDOCKCMD "!M_NAME!" "!TRYTON_BRANCH!"
              ) else if /i "%%P"=="NANTIC" (
                  if "!IS_PURE!"=="YES" (
                      call :get_from_NANTIC_PURE "!M_NAME!" "!CURRENT_VERSION!" "!REPO_ALIAS_NANTIC!"
                  ) else (
                      call :get_from_NANTIC "!M_NAME!" "!CURRENT_VERSION!" "!REPO_ALIAS_NANTIC!"
                  )
              ) 
          )
      )
  )
  
  :: 4. Validar compatibilidad post-localización/instalación y análisis dinámico
  if "!LOCATED!"=="YES" if "!IS_NATIVE!"=="NO" call :check_compat "!M_NAME!"
  if "!LOCATED!"=="YES" if "!IS_NATIVE!"=="NO" call :analyze_deps "!M_NAME!" "!M_TYPE!"

  if "!LOCATED!"=="NO" (
      if "!M_NAME!"=="account_es" if "!CURRENT_VERSION:~0,1!"=="8" (
          call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_PAQER5! !M_NAME! !WORD_VERSION! !CURRENT_VERSION:~0,1!. !INSTALL_MODU_PAQER6!"
      ) else (
          set "EXPECTED_PATH=!DIR_MODULES!\!TRYTON_LANGUAGE!\!TRYTON_BRANCH!\!M_NAME!"
          call "%DIR_SCRIPT%message.bat" "!LOG-WARN!" "!INSTALL_MODU_PAQER5! '!M_NAME!'."
          call "%DIR_SCRIPT%message.bat" "!ins_exter_action!" "!WORD_ROUTE! !WORD_TO! !WORD_FILE!: !EXPECTED_PATH!"
          (echo [!WORD_NOTFOUND!] !M_NAME! -- !WORD_ROUTE!: !EXPECTED_PATH!) >> "!file_deps_tree!"
      )
  )
  goto :process_queue
  :queue_done
  call "%DIR_SCRIPT%install_reports.bat" "%proyecto%" "10" "" "!INSTALL_MODU_PAQMS9!" "3" "!file_deps_tree!"
  exit /b

:: --- Subrutinas de apoyo para evitar errores de parser ---

:check_compat
  set "M_COMPAT=%~1"
  set "tmp_cfg=%DIR_TMP%\!M_COMPAT!_compat.cfg"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "get_container_tryton_cfg" "!M_COMPAT!" "!tmp_cfg!"
  if !errorlevel! NEQ 0 set "LOCATED=NO" & exit /b
  set "m_ver="
  for /f "usebackq tokens=2 delims==" %%V in (`findstr /b "version=" "!tmp_cfg!"`) do (
      set "m_ver=%%V"
      set "m_ver=!m_ver: =!"
  )
  if "!m_ver!"=="" exit /b
  if "!m_ver:~0,3!" NEQ "!TRYTON_BRANCH!" (
      call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!WORD_MODULE! '!M_COMPAT!' !WORD_VERSION! !m_ver! !INSTALL_MODU_PAQER3! !TRYTON_BRANCH!."
      set "LOCATED=NO"
  ) else (
      :: Validación estricta de versión: El parche del módulo debe ser <= al parche del sistema
      set "v_sys_p=0" & set "v_mod_p=0"
      for /f "tokens=3 delims=." %%p in ("!CURRENT_VERSION!") do set "v_sys_p=%%p"
      for /f "tokens=3 delims=." %%p in ("!m_ver!") do set "v_mod_p=%%p"
      
      if !v_mod_p! GTR !v_sys_p! (
          call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!WORD_VERSION! !m_ver! !INSTALL_MODU_PAQMS8! !M_COMPAT! (!INSTALL_MODU_HEAD90! !TRYTON_BRANCH!)."
      ) else (
          call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!WORD_VERSION! !m_ver! !INSTALL_MODU_PAQMS8! !M_COMPAT!."
      )
  )
exit /b

:analyze_deps
  set "M_ANALYZE=%~1"
  set "T_ANALYZE=%~2"
  set "tmp_cfg=%DIR_TMP%\!M_ANALYZE!_tryton.cfg"
  set "tmp_deps=%DIR_TMP%\!M_ANALYZE!_deps.txt"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "get_container_tryton_cfg" "!M_ANALYZE!" "!tmp_cfg!"
  if !errorlevel! NEQ 0 exit /b
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "get_module_dependencies" "!tmp_cfg!" "!tmp_deps!"
  if not exist "!tmp_deps!" exit /b
  for /f "usebackq tokens=*" %%D in ("!tmp_deps!") do (
      set "DEP_NAME=%%D"
      echo [!T_ANALYZE!] !M_ANALYZE! ^|^|-- !DEP_NAME! >> "!file_deps_tree!"
      echo !MODS_HANDLED! | findstr /i " !DEP_NAME! " >nul
      if !errorlevel! NEQ 0 (
          echo !MODS_QUEUE! | findstr /i " !DEP_NAME! " >nul
          if !errorlevel! NEQ 0 set "MODS_QUEUE=!MODS_QUEUE!!DEP_NAME! "
      )
  )
exit /b

:: Subrutina para buscar en la Comunidad (Heptapod)
:get_from_COMMUNITY
  set "m_target=%~1"
  set "full_version=%~2"
  :: Extraer versión de serie (7.0) y patch (49) para búsqueda inteligente
  set "lts_version="
  set "patch_ver="
  :: Asegurar que hg está instalado para la fase de detección en Heptapod
  if not defined HG_SYS_CHECKED (
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "install_system_package" "mercurial"
    if !ERRORLEVEL! NEQ 0 call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_PAQER1!" & goto :exit
    set "HG_SYS_CHECKED=YES"
  )

  for /f "tokens=1,2,3 delims=." %%a in ("!full_version!") do (
      set "lts_version=%%a.%%b"
      set "patch_ver=%%c"
  )
  if "!lts_version!"=="" set "lts_version=!full_version:~0,3!"
  if "!patch_ver!"=="" set "patch_ver=0"

  set "HEPTA_GROUPS=tryton-community"
  set "HEPTA_PATHS=modules"
  for %%G in (!HEPTA_GROUPS!) do (
      if "!LOCATED!"=="NO" (
          for %%P in (!HEPTA_PATHS!) do (
              if "!LOCATED!"=="NO" (
                  if "%%P"=="." ( set "path_part=" ) else ( set "path_part=%%P/" )
                  for /f "tokens=1" %%T in ("!m_target!") do (
                      set "clean_m=%%T"
                      set "R_URL=https://foss.heptapod.net/%%G/!path_part!!clean_m!"
                      call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "Intentando Heptapod URL: !R_URL!"
                      if "!LOCATED!"=="NO" (
                          call :try_hepta_community_install "!R_URL!" "!clean_m!" "!lts_version!" "!patch_ver!"
                      )
                  )
              )
          )
      )
  )
  exit /b 1

:try_hepta_community_install
  set "U_BASE=%~1"
  set "M_NAME_LOCAL=%~2"
  set "LTS_VER_LOCAL=%~3"
  set "PATCH_VER_LOCAL=%~4"
  
  :: Validación rápida: ¿Existe la URL?
  :: Se quita -L para evitar que curl de por válida una redirección a la página de login (Auth Required)
  curl -s -I "!U_BASE!" | findstr /I "200 OK" >nul
  if !errorlevel! NEQ 0 exit /b 0

  call :perform_community_install "!U_BASE!" "!M_NAME_LOCAL!" "!LTS_VER_LOCAL!"
  if !errorlevel! EQU 0 (
      set "LOCATED=YES"
  )
  exit /b 0

:perform_community_install
  set "U_RAW=%~1"
  set "M_TARGET_LOCAL=%~2"
  set "LTS_VER_FOR_INJECT=%~3"

  :: Limpiar la URL de .git si es Mercurial (ya que hg clone no lo necesita)
  set "R_CLEAN_URL=!U_RAW!"
  if /i "!R_CLEAN_URL:~-4!"==".git" set "R_CLEAN_URL=!R_CLEAN_URL:~0,-4!"

  set "LOCAL_CLONE_DIR=%DIR_TMP%\!M_TARGET_LOCAL!"
  if exist "!LOCAL_CLONE_DIR!" rmdir /s /q "!LOCAL_CLONE_DIR!"

  :: Asegurar que hg está disponible en el host para el clonado local
  where hg >nul 2>&1
  if !errorlevel! NEQ 0 (
      call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_HEAD91!"
      exit /b 1
  )

  call "%DIR_SCRIPT%message.bat" "!ins_exter_action!" "hg clone --noupdate !R_CLEAN_URL! !LOCAL_CLONE_DIR!"
  hg clone --noupdate "!R_CLEAN_URL!" "!LOCAL_CLONE_DIR!"
  if !errorlevel! NEQ 0 (
      call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_PAQER7! !R_CLEAN_URL!."
      exit /b 1
  )

  pushd "!LOCAL_CLONE_DIR!"

  :: Buscar la mejor referencia (Rama -> Default compatible -> Tag)
  set "TARGET_REF="
  set "BRANCH_FOUND=0"
  for /f "tokens=1" %%a in ('hg branches') do (
      if "%%a"=="!LTS_VER_FOR_INJECT!" set "BRANCH_FOUND=1"
  )

  if "!BRANCH_FOUND!"=="1" (
      call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!WORD_BRANCH! '!LTS_VER_FOR_INJECT!' !INSTALL_MODU_HEAD92!"
      set "TARGET_REF=!LTS_VER_FOR_INJECT!"
  ) else (
      call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!WORD_BRANCH! '!LTS_VER_FOR_INJECT!' !INSTALL_MODU_HEAD93! 'default'..."
      hg update default >nul 2>&1
      set "CFG_VER="
      for /f "usebackq tokens=2 delims==" %%v in (`findstr /b "version=" tryton.cfg 2^>nul`) do set "CFG_VER=%%v"
      if defined CFG_VER (
          set "CFG_VER=!CFG_VER: =!"
          if "!CFG_VER:~0,3!"=="!LTS_VER_FOR_INJECT!" (
              call "%DIR_SCRIPT%message.bat" "!LOG-DEBUG!" "!WORD_BRANCH! 'default' !INSTALL_MODU_HEAD94! (!CFG_VER!)."
              set "TARGET_REF=default"
          )
      )
      
      if "!TARGET_REF!"=="" (
          call "%DIR_SCRIPT%message.bat" "!LOG-DEBUG!" "!INSTALL_MODU_HEAD95! !LTS_VER_FOR_INJECT!.X !INSTALL_MODU_HEAD96!..."
          set "LASTTAG="
          for /f "tokens=1" %%a in ('hg tags ^| findstr /R "^!LTS_VER_FOR_INJECT!\.[0-9]"') do (
              if not defined LASTTAG set "LASTTAG=%%a"
          )
          if defined LASTTAG (
              set "TARGET_REF=!LASTTAG!"
          )
      )
  )

  if "!TARGET_REF!"=="" (
      call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_PAQER8! !LTS_VER_FOR_INJECT! !WORD_FOR! !M_TARGET_LOCAL!."
      popd
      rmdir /s /q "!LOCAL_CLONE_DIR!"
      exit /b 1
  )

  call "%DIR_SCRIPT%message.bat" "!ins_exter_action!" "!INSTALL_MODU_HEAD97! !TARGET_REF!"
  hg update "!TARGET_REF!" >nul 2>&1
  popd

  call "%DIR_SCRIPT%message.bat" "!ins_exter_action!" "!INSTALL_MODU_INST9! '!M_TARGET_LOCAL!' !INSTALL_MODU_INST10! %TRYTON%."
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "inject_module_from_host" "!M_TARGET_LOCAL!" "!LOCAL_CLONE_DIR!" "!LTS_VER_FOR_INJECT!" "!TRYTON_BASE_MODULE!"
  if !errorlevel! NEQ 0 (
      call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_INST11! '!M_TARGET_LOCAL!' !INSTALL_MODU_INST10!."
      if exist "!LOCAL_CLONE_DIR!" rmdir /s /q "!LOCAL_CLONE_DIR!"
      exit /b 1
  )
  set "LOCATED=YES"
  :: Auditoría con hash del clon local
  set "INS_MODULE=YES"
  set "hg_hash="
  for /f "usebackq" %%H in (`hg identify -r "!TARGET_REF!" --id "!LOCAL_CLONE_DIR!" 2^>nul`) do set "hg_hash=%%H"
  if "!hg_hash!"=="" set "hg_hash=HG_LOCAL_CLONE_UNKNOWN"
  (echo [!DATE! !TIME!] MODULE:!M_TARGET_LOCAL! PROVIDER:COMMUNITY REF:!TARGET_REF! HASH:!hg_hash! PATH:!TRYTON_BASE_MODULE!) >> "%DIR_LOG%\modules_git_audit.log"
  call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!WORD_MODULE! '!M_TARGET_LOCAL!' (!TARGET_REF!) !INSTALL_MODU_PAQMS5!."
  :: Ejecutar setup.py si existe en el módulo inyectado, similar a NANTIC_PURE
  docker exec -u 0 !CURRENT_TRYTON! bash -c "cd !TRYTON_BASE_MODULE!/!M_TARGET_LOCAL! && if [ -f setup.py ]; then python3 setup.py install --break-system-packages >/dev/null 2>&1; fi"

  if exist "!LOCAL_CLONE_DIR!" rmdir /s /q "!LOCAL_CLONE_DIR!"
  exit /b 0

:: Subrutina para buscar en NaN-tic (GitHub)
:get_from_NANTIC
  if !errorlevel! NEQ 0 call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_PAQER1!" & goto :exit
  set "m_target=%~1"
  set "full_version=%~2"
  set "lts_version=!full_version:~0,3!"
  set "patch_ver="

  if not defined GIT_SYS_CHECKED (
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "install_system_package" "git"
    if !ERRORLEVEL! NEQ 0 call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_PAQER1!" & goto :exit
    set "GIT_SYS_CHECKED=YES"
  )

  for /f "tokens=1,2,3 delims=." %%a in ("!full_version!") do (
      set "patch_ver=%%c"
  )
  if "!patch_ver!"=="" set "patch_ver=0"

  set "repo_alias=%~3"
  if "!repo_alias!"=="" set "repo_alias=trytond-!m_target!"
  :: Usar nombre de importación si está definido
  if "!M_IMPORT!"=="" ( set "check_name=!m_target!" ) else ( set "check_name=!M_IMPORT!" )

  set "R_URL=https://github.com/NaN-tic/!repo_alias!.git"
  :: NaN-tic usa guiones en lugar de underscores para el nombre del paquete
  set "m_egg_calc=!m_target:_=-!"
  set "egg_name=!M_EGG!"
  if "!egg_name!"=="" set "egg_name=nantic-trytond-!m_egg_calc!"

  :: Intentar ramas en orden: 3-dígitos, 2-dígitos, default, master, main
  set "found_branch=NO"
  if "!full_version!" NEQ "!lts_version!" (
      call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "check_git_branch_exists" "!R_URL!" "!full_version!"
      if !errorlevel! EQU 0 set "h_branch=!full_version!" & set "found_branch=YES"
  )
  if "!found_branch!"=="NO" (
      call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "check_git_branch_exists" "!R_URL!" "!lts_version!"
      if !errorlevel! EQU 0 set "h_branch=!lts_version!" & set "found_branch=YES"
  )
  if "!found_branch!"=="NO" (
      for %%B in (main master default) do (
          if "!found_branch!"=="NO" (
              call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "check_git_branch_exists" "!R_URL!" "%%B"
              if !errorlevel! EQU 0 set "h_branch=%%B" & set "found_branch=YES"
          )
      )
  )

  if "!found_branch!"=="YES" (
      call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "install_python_deps" "git+!R_URL!@!h_branch!#egg=!egg_name!" "" "trytond.modules.!check_name!"
      if !errorlevel! EQU 0 (
          set "LOCATED=YES"
          set "INS_MODULE=YES"
          call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "get_git_remote_hash" "!R_URL!" "!h_branch!"
          if !errorlevel! EQU 0 (
              set /p g_hash=<"%DIR_TMP%\git_hash.txt"
              (echo [!DATE! !TIME!] MODULE:!m_target! PROVIDER:NANTIC BRANCH:!h_branch! HASH:!g_hash! PATH:!TRYTON_BASE_MODULE!) >> "%DIR_LOG%\modules_git_audit.log"
          )
          exit /b 0
      )
  )
  exit /b 1

:: Subrutina para módulos NaN-tic que NO tienen setup.py (clonar e inyectar)
:get_from_NANTIC_PURE
  :: Asegurar que git está instalado para el entorno
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "install_system_package" "git"
  set "m_target=%~1"
  set "full_version=%~2"
  set "lts_version=!full_version:~0,3!"
  set "repo_alias=%~3"
  set "R_URL=https://github.com/NaN-tic/!repo_alias!.git"
  
  :: Determinar rama
  set "h_branch=!lts_version!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "check_git_branch_exists" "!R_URL!" "!h_branch!"
  if !errorlevel! NEQ 0 set "h_branch=main"

  call "%DIR_SCRIPT%message.bat" "!ins_exter_action!" "!INSTALL_MODU_HEAD99! !m_target!' !WORD_FROM! NaN-tic..."
  set "LOCAL_CLONE_DIR=%DIR_TMP%\!m_target!"
  if exist "!LOCAL_CLONE_DIR!" rd /s /q "!LOCAL_CLONE_DIR!"
  git clone --depth 1 -b !h_branch! "!R_URL!" "!LOCAL_CLONE_DIR!" >nul 2>&1
  
  if exist "!LOCAL_CLONE_DIR!\tryton.cfg" (
      call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "inject_module_from_host" "!m_target!" "!LOCAL_CLONE_DIR!" "!lts_version!" "!TRYTON_BASE_MODULE!"
      if !errorlevel! EQU 0 (
          :: Segundo paso: Ejecutar instalación si existe setup.py (ignora errores de compatibilidad como use_2to3)
          call "%DIR_SCRIPT%message.bat" "!ins_exter_action!" "!INSTALL_MODU_HEAD98! '!m_target!'..."
          docker exec -u 0 !CURRENT_TRYTON! bash -c "cd !TRYTON_BASE_MODULE!/!m_target! && if [ -f setup.py ]; then python3 setup.py install --break-system-packages >/dev/null 2>&1; fi"
          set "LOCATED=YES"
          set "INS_MODULE=YES"
          (echo [!DATE! !TIME!] MODULE:!m_target! PROVIDER:NANTIC_PURE BRANCH:!h_branch! HASH:LOCAL_GIT PATH:!TRYTON_BASE_MODULE!) >> "%DIR_LOG%\modules_git_audit.log"
          if exist "!LOCAL_CLONE_DIR!" rd /s /q "!LOCAL_CLONE_DIR!"
          exit /b 0
      )
  )
  :: Limpieza en caso de fallo
  if exist "!LOCAL_CLONE_DIR!" rd /s /q "!LOCAL_CLONE_DIR!"
  exit /b 1

:get_NANTIC_identity
  set "M_IMPORT=!M_NAME!"
  set "M_EGG="
  set "REPO_ALIAS_NANTIC=trytond-!M_NAME!"
  :: Mapeos específicos de NaN-tic (Nombre en depends -> Identidad en GitHub/Pip)
  if /i "!M_NAME!"=="account_es"             set "M_EGG=nantic-account-es" & set "REPO_ALIAS_NANTIC=trytond-account_es"
  if /i "!M_NAME!"=="account_es_aeat"        set "M_EGG=nantic-account-es-aeat" & set "REPO_ALIAS_NANTIC=trytond-account_es_aeat"
  if /i "!M_NAME!"=="account_payment_type"   set "M_EGG=nantic-account-payment-type" & set "REPO_ALIAS_NANTIC=trytond-account_payment_type"
  if /i "!M_NAME!"=="account_es_verifactu"   set "M_EGG=nantic-aeat-verifactu" & set "REPO_ALIAS_NANTIC=trytond-aeat_verifactu" & set "M_IMPORT=aeat_verifactu"
  if /i "!M_NAME!"=="aeat_verifactu"         set "M_EGG=nantic-aeat-verifactu" & set "REPO_ALIAS_NANTIC=trytond-aeat_verifactu" & set "M_IMPORT=aeat_verifactu"
  if /i "!M_NAME!"=="account_es_sii"         set "M_EGG=nantic-aeat-sii" & set "REPO_ALIAS_NANTIC=trytond-aeat_sii" & set "M_IMPORT=aeat_sii"
  if /i "!M_NAME!"=="aeat_sii"               set "M_EGG=nantic-aeat-sii" & set "REPO_ALIAS_NANTIC=trytond-aeat_sii" & set "M_IMPORT=aeat_sii"
  if /i "!M_NAME!"=="aeat_party_validation"  set "M_EGG=nantic-aeat-party-validation" & set "REPO_ALIAS_NANTIC=trytond-aeat_party_validation"
  if /i "!M_NAME!"=="certificate_manager"    set "M_EGG=nantic-certificate-manager" & set "REPO_ALIAS_NANTIC=trytond-certificate_manager"
  if /i "!M_NAME!"=="account_invoice_facturae_electronet" set "M_EGG=nantic-account-invoice-facturae-electronet" & set "REPO_ALIAS_NANTIC=trytond-account_invoice_facturae_electronet"
  if /i "!M_NAME!"=="edocument_es_facturae"  set "M_EGG=nantic-account-invoice-facturae-electronet" & set "REPO_ALIAS_NANTIC=trytond-account_invoice_facturae_electronet" & set "M_IMPORT=account_invoice_facturae_electronet"
  if /i "!M_NAME!"=="account_invoice_facturae" set "M_EGG=nantic-account-invoice-facturae" & set "REPO_ALIAS_NANTIC=trytond-account_invoice_facturae"
  if /i "!M_NAME!"=="account_es_facturae"      set "M_EGG=nantic-account-invoice-facturae" & set "REPO_ALIAS_NANTIC=trytond-account_invoice_facturae" & set "M_IMPORT=account_invoice_facturae"
  if /i "!M_NAME!"=="account_invoice_discount" set "M_EGG=nantic-account-invoice-discount" & set "REPO_ALIAS_NANTIC=trytond-account_invoice_discount"
  if /i "!M_NAME!"=="party_tradename"          set "M_EGG=nantic-party-tradename" & set "REPO_ALIAS_NANTIC=trytond-party_tradename"
  if /i "!M_NAME!"=="account_invoice_company_currency" set "M_EGG=nantic-account-invoice-company-currency" & set "REPO_ALIAS_NANTIC=trytond-account_invoice_company_currency"
  if /i "!M_NAME!"=="account_invoice_shipment" set "M_EGG=nantic-account-invoice-shipment" & set "REPO_ALIAS_NANTIC=trytond-account_invoice_shipment"
  if /i "!M_NAME!"=="stock_origin_sale"        set "M_EGG=nantic-stock-origin-sale" & set "REPO_ALIAS_NANTIC=trytond-stock_origin_sale"
  if /i "!M_NAME!"=="stock_origin"             set "M_EGG=nantic-stock-origin" & set "REPO_ALIAS_NANTIC=trytond-stock_origin"
  if /i "!M_NAME!"=="account_invoice_vat_required" set "M_EGG=nantic-account-invoice-vat-required" & set "REPO_ALIAS_NANTIC=trytond-account_invoice_vat_required"
exit /b

:check_NANTIC_pure
  set "IS_PURE=NO"
  :: Módulos que fallan con PIP por tener setup.py antiguos (no incluyen XMLs o dan errores use_2to3)
  :: Al usar el método PURE (Git Clone + CP), nos aseguramos de tener el contenido completo (XML, locale, etc.)
  if /i "!REPO_ALIAS_NANTIC!"=="trytond-account_common" set "IS_PURE=YES"
  if /i "!REPO_ALIAS_NANTIC!"=="trytond-account_invoice_facturae" set "IS_PURE=YES"
  if /i "!REPO_ALIAS_NANTIC!"=="trytond-account_es_facturae" set "IS_PURE=YES"
  if /i "!REPO_ALIAS_NANTIC!"=="trytond-account_invoice_facturae_electronet" set "IS_PURE=YES"
  if /i "!REPO_ALIAS_NANTIC!"=="trytond-account_invoice_shipment" set "IS_PURE=YES"
  if /i "!REPO_ALIAS_NANTIC!"=="trytond-account_invoice_discount" set "IS_PURE=YES"
  if /i "!REPO_ALIAS_NANTIC!"=="trytond-party_tradename" set "IS_PURE=YES"
  if /i "!REPO_ALIAS_NANTIC!"=="trytond-stock_origin" set "IS_PURE=YES"
  if /i "!REPO_ALIAS_NANTIC!"=="trytond-stock_origin_sale" set "IS_PURE=YES"
  if /i "!REPO_ALIAS_NANTIC!"=="trytond-account_payment_type" set "IS_PURE=YES"
  if /i "!REPO_ALIAS_NANTIC!"=="trytond-certificate_manager" set "IS_PURE=YES"
  if /i "!REPO_ALIAS_NANTIC!"=="trytond-account_es" if "!CURRENT_VERSION:~0,1!"=="8" set "IS_PURE=YES"
  if /i "!REPO_ALIAS_NANTIC!"=="trytond-account_es_aeat" set "IS_PURE=YES"
  if /i "!M_NAME!"=="account_common" set "IS_PURE=YES"
  if /i "!M_NAME!"=="account_invoice_facturae" set "IS_PURE=YES"
  if /i "!M_NAME!"=="account_es_facturae"      set "IS_PURE=YES"
  if /i "!M_NAME!"=="account_invoice_shipment" set "IS_PURE=YES"
  if /i "!M_NAME!"=="account_invoice_discount" set "IS_PURE=YES"
  if /i "!M_NAME!"=="party_tradename" set "IS_PURE=YES"
  if /i "!M_NAME!"=="account_invoice_vat_required" set "IS_PURE=YES"
exit /b

:get_from_TRYDOCKCMD
  set "m_target=%~1"
  set "b_target=%~2"
  set "h_path=!DIR_MODULES!\!TRYTON_LANGUAGE!\!b_target!\!m_target!"
  if exist "!h_path!" (
      call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "inject_module_from_host" "!m_target!" "!h_path!" "!b_target!" "!TRYTON_BASE_MODULE!"
      if !errorlevel! EQU 0 (
          set "LOCATED=YES"
          set "INS_MODULE=YES"
          call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!WORD_MODULE! !m_target! !INSTALL_MODU_PAQMS6!."
          (echo [!DATE! !TIME!] MODULE:!m_target! PROVIDER:TRYDOCKCMD BRANCH:!b_target! HASH:LOCAL_CP PATH:!TRYTON_BASE_MODULE!) >> "%DIR_LOG%\modules_git_audit.log"
      )
  )
 exit /b 0

:install_module_external
  set "EXTERNAL_SQL=%~1"
  set "EXTERNAL_MODULE=%~2"
  set "state_veri="
  set /a numer_ext+=1
  set "state_veri="
  call :logger "%ins_exter_action%" "[%numer_ext%] !INSTALL_MODU_HEAD75! %EXTERNAL_MODULE%" "8"
  for /f "usebackq" %%a in (`docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U "%POSTGRES%" -d "!DB_NAME!" -At -c "SELECT state FROM ir_module WHERE name='!EXTERNAL_SQL!';" 2^>nul`) do set "state_veri=%%a"
  if %ERRORLEVEL% NEQ 0  exit /b
  if /i "!state_veri!"=="activated" exit /b
  set "FEX= !INSTALL_MODU_HEADMO! (!EXTERNAL_MODULE: =, !)"
  call :logger "%ins_exter_action%" "[%numer_ext%] !INSTALL_MODU_HEAD76! !FEX!" "8"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timemodex!" "1" 
  set "cmd=!COM2! !COM1! -l !TRYTON_LANGUAGE! -u !EXTERNAL_MODULE! --activate-dependencies !COM3!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%SERVER%" "!cmd!" "!DB_NAME!" "" "%file_logger%" "YES" "" ""
  exit /b

:update_modules_trytond
  call :logger "%ins_exter_action%" "!INSTALL_MODU_HEAD34!" "3"
  :: El comando update-modules-list NO lleva -l y actualiza la tabla ir_module con lo que hay en disco
  set "cmd=!COM2! !COM1! --update-modules-list"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%SERVER%" "!cmd!" "!DB_NAME!" "" "%file_logger%" "YES" "" ""
  call :logger "%ins_exter_action%" "!INSTALL_MODU_HEAD34_ALL!" "3"
  :: El comando --all con -l reconstruye toda la base de datos y refresca las traducciones de los menús
  set "cmd=!COM2! !COM1! -l !TRYTON_LANGUAGE! --all !COM3!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "trytond_services" "%SERVER%" "!cmd!" "!DB_NAME!" "" "%file_logger%" "YES" "" ""
  exit /b


:stop_start_trytond
   :: Reiniciar servicios para estabilizar el sistema y limpiar caché (Solución al error #ERROR#)
   call :logger "!ins_exter_action!" "!LOG_WORK_STOP!" "3"
   call "%DIR_SCRIPT%startdown.bat" "%proyecto%" "%CHECK%" "STOP"
   call :logger "!ins_exter_action!" "!LOG_WORK_START!" "3"
   call "%DIR_SCRIPT%startup.bat" "%proyecto%" "%CHECK%"
 exit /b

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:exit
  endlocal
  exit /b 0
