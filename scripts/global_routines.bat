@echo off
:: ===============================================================================
:: PROGRAM:   global_routines.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    Telepieza
:: COLLABORATOR: Gemini Code Assist
:: VERSION:   1.1.30
:: DATE:      20/05/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Subrutinas globales 
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul

set "proyecto=%~1"
set "glo_action=%~2"
set "param1=%~3"
set "param2=%~4"
set "param3=%~5"
set "param4=%~6"
set "param5=%~7"
set "param6=%~8"
set "param7=%~9"
shift
set "param8=%~9"

:: Analiza si la llamada es del tcd.bat
call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
:: Se puede simplificar mucho la llamada a las diferentes subrutinas, pero me gusta más como lo he dejado.
:: el ejemplo de simplificacion es quitar todos los if y dejar call :%glo_action% "!param1!" "!param2!" "!param3!" "!param4!"

if /i "%glo_action%" == "timeout_start"             call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!] [!param2!] [!param3!]" & call :timeout_start "!param1!" "!param2!" "!param3!" & goto :exit
if /i "%glo_action%" == "fill_in_field"            call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!] [!param2!] [!param3!] [!param4!]" & call :fill_in_field "!param1!" "!param2!" "!param3!" "!param4!" & goto :exit
if /i "%glo_action%" == "display_file_event_all"   call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!] [!param2!]" & call :display_file_event_all "!param1!" "!param2!" & goto :exit
if /i "%glo_action%" == "check_remote_tryton_cfg"  call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!] [!param2!]" & call :check_remote_tryton_cfg "!param1!" "!param2!" & goto :exit
if /i "%glo_action%" == "install_python_deps"      call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!] [!param2!] [!param3!] [!param4!]" & call :install_python_deps "!param1!" "!param2!" "!param3!" "!param4!" & goto :exit
if /i "%glo_action%" == "get_container_tryton_cfg" call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!] [!param2!]" & call :get_container_tryton_cfg "!param1!" "!param2!" & goto :exit
if /i "%glo_action%" == "get_module_dependencies"  call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!] [!param2!]" & call :get_module_dependencies "!param1!" "!param2!" & goto :exit
if /i "%glo_action%" == "check_git_branch_exists"  call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!] [!param2!]" & call :check_git_branch_exists "!param1!" "!param2!" & goto :exit
if /i "%glo_action%" == "get_git_remote_hash"      call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!] [!param2!]" & call :get_git_remote_hash "!param1!" "!param2!" & goto :exit
if /i "%glo_action%" == "check_system_version"     call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action!" & call :check_system_version & goto :exit
if /i "%glo_action%" == "audit_xml_models"         call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!]" & call :audit_xml_models "!param1!" & goto :exit
if /i "%glo_action%" == "fix_xml_models"           call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!]" & call :fix_xml_models "!param1!" & goto :exit
if /i "%glo_action%" == "install_system_package"   call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!]" & call :install_system_package "!param1!" & goto :exit
if /i "%glo_action%" == "inject_module_from_host"  call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!] [!param2!] [!param3!] [!param4!]" & call :inject_module_from_host "!param1!" "!param2!" "!param3!" "!param4!" & goto :exit
if /i "%glo_action%" == "trytond_services"         call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!] [!param2!] [!param3!] [!param4!] [!param5!] [!param6!] [!param7!] [!param8!]" & call :trytond_services "!param1!" "!param2!" "!param3!" "!param4!" "!param5!" "!param6!" "!param7!" "!param8!" & goto :exit
goto :exit

:: Temporizador. recibe segundos y procede a realizar un timeout
:: Si los segundos son más de 5, Si recibe 10 segundos, genera una barra, ejemplo : 10s .......... 0s
:timeout_start
  set "i_second=%~1"
  set /a "c_second=1"
  set /a "r_second=0"
  set "point="
  set "bar="
  if /i "%~3" NEQ "" set "bar=%~3"
  :: Limpiar posibles espacios en el flag de silencio
  if defined bar set "bar=!bar: =!"
  :: Menor de 5 segundos no visualiza la barra de puntos.
  if !i_second! LSS 5 (
     timeout /t !i_second! >nul
     exit /b
  )
  :: Se indica expresamente no sacar la barra de puntos.
  if /i "%bar%" EQU "N" (
     timeout /t !i_second! >nul
     exit /b
  )

  if /i "%~2" NEQ "" (
   set /a "c_second=%~2"
   if "%c_second%" EQU 0 set /a "c_second=1"
  )
  :: barra de puntos
  if %c_second% GTR %i_second% set /a "i_second=%c_second%"
  for /L %%i in (1, 1, %c_second%) do (
    set "point=!point!."
  )
  set /a r_second=(%i_second% + %c_second% - 1) / %c_second%
  if "%r_second%" EQU 0 set /a r_second=1
  <nul set /p=%r_second%s 
  for /L %%i in (1, 1, %r_second%) do (
      <nul set /p=!point!
      timeout /t %c_second% >nul
 )
 <nul set /p=. 0s
 echo.
 exit /b

:: Recibe un texto y genera un subrayado igual a la longitud del texto
:: Ejemplo TRYDOCKCMD MANAGER
::         ------------------
:fill_in_field
  set "fil_action=%~1"
  set "text=%~2"
  set /a "numer=0"
  if /i "%~3" NEQ "" set /a "numer=%~3"
  set "file_cab=%~4"
  set "MESSAGE="
  :: longitud hasta 500 o longitud del texto
  set "len=0"
:calcLength
  if defined text if not "!text:~%len%,1!"=="" if !len! LSS 500 (
    set /a len+=1
    goto :calcLength
  )
  :: bucle simple para generar guiones
  for /L %%I in (1,1,!len!) do set "MESSAGE=!MESSAGE!-"
  echo.
  call "%DIR_SCRIPT%message.bat" "%fil_action%" "%text%" "%numer%"
  if /i "%file_cab%" NEQ "" echo # %text% >> "%file_cab%"
  call "%DIR_SCRIPT%message.bat" "%MENU%" "%MESSAGE%" "%numer%"
  if /i "%file_cab%" NEQ "" echo # %MESSAGE% >> "%file_cab%"
  echo.
  exit /b

: Recibe un fichero, lo lee y es visualizado por consola y grabado en el fichero de log
:display_file_event_all
  set "event_default_file=%~1"
  set "file_temp=%~2"
  :: 1. Validar que el archivo existe y no está vacío
  if not exist "%file_temp%" exit /b
  :: 2. Recorre cada línea completa del fichero
  for /f "usebackq delims=" %%L in ("%file_temp%") do (
    set "clean_line=%%L"

    :: Limpiar caracteres críticos (especialmente &) ANTES de procesar la línea
    set "clean_line=!clean_line:&=y!"
    set "clean_line=!clean_line:)=]!"
    set "clean_line=!clean_line:(=[!"
    set "clean_line=!clean_line:<=]!"
    set "clean_line=!clean_line:>=[!"
    set "clean_line=!clean_line:"=!"

    set "event_now=!event_default_file!"

    :: Filtrar ruidos de librerías y mensajes de carga que ensucian el reporte
    set "is_noise=N"
    echo "!clean_line!" | findstr /I "RequestsDependencyWarning warnings.warn DeprecationWarning ImportWarning UserWarning XMLSchema.xsd braintree zeep crypt trytond_setup.conf WARNING frozen importlib dist-packages site-packages _crypt cgi < > lib/python" >nul && set "is_noise=Y"
    if "!is_noise!"=="Y" goto :next_line_loop

    :: Analizar contenido de la línea para ajustar el color dinámicamente
    echo "!clean_line!" | findstr /I "!WORD_INFO! !WORD_NATIVE!" >nul
    if !errorlevel! EQU 0 set "event_now=!LOG-INFO!"

    echo "!clean_line!" | findstr /I "ERROR Traceback AttributeError ValueError ParsingError" >nul
    if !errorlevel! EQU 0 set "event_now=!LOG-ERROR!"

    echo "!clean_line!" | findstr /I "!WORD_EXTERNAL!" >nul
    if !errorlevel! EQU 0 set "event_now=!LOG-WARN!"

    :: Si la línea es un WARNING de Python, degradar de ERROR a WARN
    echo "!clean_line!" | findstr /I "!WORD_WARNING!" >nul
    if !errorlevel! EQU 0 set "event_now=!LOG-WARN!"

    call "%DIR_SCRIPT%message.bat" "!event_now!" "!WORD_MESSAGE! !clean_line!"
    :next_line_loop
    set "is_noise=N"
  )
  exit /b

:audit_xml_models
  set "folder=%~1"
  call "%DIR_SCRIPT%message.bat" "%CHECK%" "!INSTALL_MODU_HEAD87! !folder!..."
  set "found_err=0"
  for /r "!folder!" %%f in (*.xml) do (
      findstr /I "name=\"model\"" "%%f" | findstr /I "ref=" >nul
      if !errorlevel! EQU 0 (
          set "found_err=1"
          call "%DIR_SCRIPT%message.bat" "!LOG-WARN!" "!INSTALL_MODU_HEAD88! %%f"
          findstr /n /I "name=\"model\"" "%%f" | findstr /I "ref="
      )
  )
  if "!found_err!"=="0" call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!INSTALL_MODU_HEAD89!"
  exit /b !found_err!

:fix_xml_models
  set "folder=%~1"
  call "%DIR_SCRIPT%message.bat" "%CHECK%" "!INSTALL_MODU_HEAD84! folder!..."
  :: Ejecuta PowerShell en una sola línea para evitar que Batch intente parsear paréntesis y operadores como -replace
  powershell -Command "Get-ChildItem -Path '!folder!' -Filter *.xml -Recurse | ForEach-Object { $c = Get-Content $_.FullName -Raw; $n = [regex]::Replace($c, 'ref=\"model_(?<m>[^\"\s]+)\"', { param($obj) 'search=\"[(''model'', ''='', ''' + ($obj.Groups['m'].Value.Replace('_', '.')) + ''')]\"' }); if ($c -ne $n) { $n | Set-Content $_.FullName -Encoding UTF8; Write-Host 'Revertido a search: ' $_.FullName } }"
  call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!INSTALL_MODU_HEAD83!"
  exit /b

:check_system_version
  echo.
  call "%DIR_SCRIPT%message.bat" "%CHECK%" "--- !INSTALL_MODU_HEAD85! ---"
  docker exec "!CURRENT_TRYTON!" trytond-admin --version > "!DIR_TMP!\t_ver.txt" 2>&1
  set /p v_real=<"!DIR_TMP!\t_ver.txt"
  call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!INSTALL_MODU_HEAD86!!v_real!"
  exit /b

:get_container_tryton_cfg
  set "m_name=%~1"
  set "local_path=%~2"
  :: Buscar ruta física del módulo
  docker exec "!CURRENT_TRYTON!" bash -c "find !TRYTON_BASE_MODULE! -name tryton.cfg | grep /!m_name!/" > "!DIR_TMP!\cfg_path.txt" 2>&1
  set /p remote_path=<"!DIR_TMP!\cfg_path.txt"
  if "!remote_path!"=="" (
      :: Intento alternativo via python para modulos instalados como eggs/pip
      docker exec "!CURRENT_TRYTON!" python3 -c "import os, trytond.modules.!m_name! as m; print(os.path.join(os.path.dirname(m.__file__), 'tryton.cfg'))" > "!DIR_TMP!\cfg_path.txt" 2>&1
      set /p remote_path=<"!DIR_TMP!\cfg_path.txt"
  )
  if "!remote_path!"=="" exit /b 1
  docker cp "!CURRENT_TRYTON!:!remote_path!" "!local_path!" >nul 2>&1
  exit /b !errorlevel!

:check_remote_tryton_cfg
  set "url=%~1"
  set "branch=%~2"
  :: Validar si el repositorio es accesible (evita prompts de Git)
  curl -s --head "!url!" | findstr /I "200 OK" >nul
  if !errorlevel! NEQ 0 exit /b 1
  exit /b 0

:check_git_branch_exists
  set "repo_url=%~1"
  set "branch_name=%~2"
  :: Limpieza profunda de la URL: eliminar espacios, comillas y slashes finales
  set "repo_url=!repo_url:"=!"
  set "repo_url=!repo_url:'=!"
  :: Tomar solo el primer token para eliminar de raíz espacios y caracteres invisibles (CR/LF)
  for /f "tokens=1" %%u in ("!repo_url!") do set "repo_url=%%u"
  
  :strip_slashes_exists
  if "!repo_url:~-1!"=="/" (
      set "repo_url=!repo_url:~0,-1!"
      goto :strip_slashes_exists
  )

  :: --- LÓGICA EXCLUSIVA HEPTAPOD (Mercurial hg) ---
  echo "!repo_url!" | findstr /I "heptapod.net" >nul
  if !errorlevel! EQU 0 (
      set "u_hg=!repo_url!"
      if /i "!u_hg:~-4!"==".git" set "u_hg=!u_hg:~0,-4!"
      
      :: Validación nativa vía Mercurial (hg) dentro del contenedor
      docker exec "!CURRENT_TRYTON!" hg --version >nul 2>&1
      if !errorlevel! EQU 0 (
          :: hg identify <URL>#<REF> devuelve 0 si la referencia existe
          set "ref_hg=!branch_name!"
          if /i "!ref_hg:~0,7!"=="branch/" set "ref_hg=!ref_hg:branch/=!"
          
          docker exec "!CURRENT_TRYTON!" hg identify "!u_hg!#!ref_hg!" >nul 2>&1
          if !errorlevel! EQU 0 (
              call "%DIR_SCRIPT%message.bat" "!LOG-DEBUG!" "Heptapod HG: Rama/Tag '!ref_hg!' encontrado."
              exit /b 0
          )
      )
      :: Fallback a curl contra la web de Heptapod (sin usar git)
      curl -s -L --head "!u_hg!/-/tree/!branch_name!" | findstr /I "200 OK" >nul
      if !errorlevel! EQU 0 (
          call "%DIR_SCRIPT%message.bat" "!LOG-DEBUG!" "Heptapod Web: Rama/Tag '!branch_name!' encontrado via curl."
          exit /b 0
      )
      :: Si es Heptapod y falló HG/Curl, no permitimos que siga hacia Git
      exit /b 1
  )

  :: Asegurar extensión .git (Solo para proveedores Git no-Heptapod)
  if /i "!repo_url:~-4!" NEQ ".git" (
      set "repo_url=!repo_url!.git"
  )

  :: Segunda pasada de tokenización para garantizar limpieza absoluta tras añadir .git
  for /f "tokens=1" %%u in ("!repo_url!") do set "repo_url=%%u"

  call "%DIR_SCRIPT%message.bat" "!LOG-DEBUG!" "check_git_branch_exists - repo_url FINAL: !repo_url!"
  :: Eliminar posibles espacios accidentales al final
  set "branch_name=!branch_name: =!"
  :: Desactivar prompts y helpers de credenciales para evitar bloqueos/popups en ramas inexistentes
  set "GIT_TERMINAL_PROMPT=0"
  :: Verificar si git está en el path del host
  where git >nul 2>&1 || exit /b 1
  :: Comprobar tanto ramas (heads) como etiquetas (tags)
  git -c credential.helper= ls-remote --heads --tags "!repo_url!" "!branch_name!" > "!DIR_TMP!\git_ls.txt" 2>&1
  set "git_err=!errorlevel!"
  findstr /R /C:"/!branch_name!$" "!DIR_TMP!\git_ls.txt" >nul 2>&1
  set "find_res=!errorlevel!"
  
  if !find_res! NEQ 0 (
      for /f "usebackq delims=" %%e in ("!DIR_TMP!\git_ls.txt") do call "%DIR_SCRIPT%message.bat" "!LOG-DEBUG!" "Git Result [!branch_name!]: %%e"
  )
  exit /b !find_res!

:get_git_remote_hash
  set "GIT_TERMINAL_PROMPT=0"
  set "repo_url=%~1"
  set "repo_url=!repo_url:"=!"
  set "repo_url=!repo_url:'=!"
  :: Limpieza atómica de caracteres invisibles
  for /f "tokens=1" %%u in ("!repo_url!") do set "repo_url=%%u"
  
  :strip_slashes_hash
  if "!repo_url:~-1!"=="/" (
      set "repo_url=!repo_url:~0,-1!"
      goto :strip_slashes_hash
  )

  :: --- LÓGICA HEPTAPOD ---
  echo "!repo_url!" | findstr /I "heptapod.net" >nul
  if !errorlevel! EQU 0 (
      set "u_hg=!repo_url!"
      if /i "!u_hg:~-4!"==".git" set "u_hg=!u_hg:~0,-4!"
      set "ref_hg=%~2"
      if /i "!ref_hg:~0,7!"=="branch/" set "ref_hg=!ref_hg:branch/=!"
      
      docker exec "!CURRENT_TRYTON!" hg identify "!u_hg!" -r "!ref_hg!" --id > "%DIR_TMP%\git_hash.txt" 2>nul
      exit /b 0
  )

  if /i "!repo_url:~-4!" NEQ ".git" set "repo_url=!repo_url!.git"
  for /f "tokens=1" %%u in ("!repo_url!") do set "repo_url=%%u"

  call "%DIR_SCRIPT%message.bat" "!LOG-DEBUG!" "get_git_remote_hash - repo_url FINAL: !repo_url!"
  :: Usamos %DIR_TMP% para asegurar la expansión correcta dentro de una tubería (pipe)
  git -c credential.helper= ls-remote "!repo_url!" "%~2" 2>nul | for /f "tokens=1" %%a in ('more') do echo %%a > "%DIR_TMP%\git_hash.txt"
  exit /b 0

:inject_module_from_host
  set "m_name=%~1"
  set "h_path=%~2"
  set "branch=%~3"
  set "c_base=%~4"
  if not exist "!h_path!\tryton.cfg" exit /b 1
  set "m_ver="
  for /f "usebackq tokens=2 delims==" %%V in (`findstr /b "version=" "!h_path!\tryton.cfg" 2^>nul`) do (
      set "m_ver=%%V"
      set "m_ver=!m_ver: =!"
  )
  echo !m_ver! > "!DIR_TMP!\inject_ver.txt"
  if "!m_ver!"=="" exit /b 1
  if "!m_ver:~0,3!" NEQ "!branch!" exit /b 2
  :: Asegurar que el destino no existe para evitar anidamiento o conflictos con docker cp
  docker exec -u 0 !CURRENT_TRYTON! rm -rf "!c_base!/!m_name!" >nul 2>&1
  docker cp "!h_path!" !CURRENT_TRYTON!:"!c_base!/!m_name!" >nul 2>&1
  if !errorlevel! NEQ 0 exit /b 3
  docker exec -u 0 !CURRENT_TRYTON! chown -R root:root "!c_base!/!m_name!" >nul 2>&1
  docker exec -u 0 !CURRENT_TRYTON! chmod -R 755 "!c_base!/!m_name!" >nul 2>&1
  exit /b 0

:get_module_dependencies
  set "cfg_file=%~1"
  set "out_file=%~2"
  if exist "!out_file!" del "!out_file!"
  :: Usamos una instrucción de una sola línea y evitamos operadores conflictivos como -match si es posible, o los encerramos en una cadena atómica
  powershell -Command "$c = Get-Content '!cfg_file!' -Raw; if ($c -match '(?s)\[dependencies\]\s*(.*?)(?:\r?\n\s*\[|$)') { $matches[1].Split(\"`n\").Trim() | Where-Object { $_ -ne '' -and $_ -notmatch '^#' } | Out-File -FilePath '!out_file!' -Encoding UTF8 }"
  exit /b 0

:install_system_package
  REM %1 = package name
  set "package_name=%~1"
  :: Check if the package is already installed using dpkg -s (accurate for Debian/Tryton)
  docker exec -u 0 "!CURRENT_TRYTON!" dpkg -s !package_name! >nul 2>&1
  if !errorlevel! EQU 0 (
    call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!SYSTEM_PACKAGE! '!package_name!' !INSTALL_MODU_PAQMS2! '!CURRENT_TRYTON!'."
    exit /b 0
  )
  :: If not installed, install it
  call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!INSTALL_MODU_PAQMS3! '!package_name!' !INSTALL_MODU_PAQMS4! '!CURRENT_TRYTON!'..."
  docker exec -u 0 "!CURRENT_TRYTON!" bash -c "apt-get update && apt-get install -y !package_name!"
  if !errorlevel! EQU 0 (
    call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!SYSTEM_PACKAGE! '!package_name!' !INSTALL_MODU_PAQMS5!."
    exit /b 0
  ) else (
    call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_PAQER2! '!package_name!'."
    exit /b 1
  )

:install_python_deps
  REM %1 = paquete pip
  REM %2 = dependencias apt (opcional)
  REM %3 = nombre de importación para verificar (opcional)
  REM %4 = target path (opcional, para instalar modulos en trytond/modules)
  set "package_name=%~1"
  set "check_import=%~3"
  if "!check_import!"=="" set "check_import=%~1"
  :: Casos especiales donde el nombre del paquete pip != nombre de importación
  if /i "%package_name%" == "pyOpenSSL" set "check_import=OpenSSL"
  :: 1. Comprobar si el paquete ya está instalado en el contenedor
  docker exec -u 0 "!CURRENT_TRYTON!" bash -c "python3 -c \"import !check_import!\"" >nul 2>&1
  if !errorlevel! EQU 0 (
    call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!WORD_MODULE! '!package_name!' !INSTALL_MODU_PAQMS2!."
    exit /b 0
  )
  :: 2. Si no está instalado, proceder con la instalación
  set "sys_deps=%~2"
  set "target_dir=%~4"
  set "pip_target="
  if "!target_dir!" NEQ "" set "pip_target=--target !target_dir!"

  if "!sys_deps!" NEQ "" (
      docker exec -u 0 "!CURRENT_TRYTON!" bash -c "export GIT_TERMINAL_PROMPT=0 && apt-get update >/dev/null 2>&1 && apt-get install -y !sys_deps! >/dev/null 2>&1 && pip install --no-cache-dir --no-deps --ignore-installed !pip_target! !package_name! --break-system-packages >/dev/null 2>&1"
  ) else (
      docker exec -u 0 "!CURRENT_TRYTON!" bash -c "export GIT_TERMINAL_PROMPT=0 && pip install --no-cache-dir --no-deps --ignore-installed !pip_target! !package_name! --break-system-packages >/dev/null 2>&1"
  )
  :: Si el comando anterior falló, !errorlevel! será distinto de 0
  if !errorlevel! EQU 0 (
    call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!SYSTEM_PACKAGE! '!package_name!' !INSTALL_MODU_PAQMS5!."
    exit /b 0
  ) else (
    call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_PAQER2! '!package_name!'."
    exit /b 1
  )

:trytond_services
   REM %1 = Servicio server o postgres
   REM %2 = comando completo a ejecutar (trytond-admin o psql SQL)
   REM %3 = Base de datos tryton - tryton-demo
   REM %4 = logfile stdout (opcional)
   REM %5 = errfile stderr (opcional)
   REM %6 = YES (añadir en vez de sobrescribir)
   REM %7 = label (Añadir info al mensaje del log)
   REM %8 = Mensaje (Añadir info al mensaje del log)
   set "servicio=%~1"
   set "cmd=%~2"
   set "db_postgres=%~3"
   set "logfile=%~4"
   set "errfile=%~5"
   set "add=%~6"
   set "label=%~7"
   set "ser_msg=%~8"

   if not "%logfile%"=="" if /i "%add%" NEQ "YES" if exist "%logfile%" del "%logfile%" >nul
   if not "%errfile%"=="" if /i "%add%" NEQ "YES" if exist "%errfile%" del "%errfile%" >nul
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
    docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%SERVER%" bash -c "export PYTHONWARNINGS=ignore && %cmd%" %redir_out% %redir_err%
  )
  if /i "%servicio%"=="%POSTGRES%" (
    docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U postgres -d "%db_postgres%" -At -c "%cmd%" %redir_out% %redir_err%
  )
  set "status=%ERRORLEVEL%"
  if %status% EQU 0 (
    if /i "%ins_tryton_action%" EQU "%INS%" call :timeout_start "10" "1" "N"
    if "%label%" NEQ "" (
      call "%DIR_SCRIPT%message.bat" "%CHECK%" "!WORD_MESSAGE! !glo_action! %label%"
      if exist "%logfile%" (
        set /p count=<"%logfile%"
        call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "%ser_msg% (!count! %label%)"
      )
    )
  )
  if %status% NEQ 0 (
     if exist "%errfile%" if not "%errfile%"=="" call :display_file_event_all "!LOG-ERROR!" "%errfile%"
     if exist "%logfile%" if not "%logfile%"=="" call :display_file_event_all "!LOG-INFO!" "%logfile%"
     exit /b %status%
  )
  exit /b 0

:exit
  set "RES_ERROR=%errorlevel%"
  endlocal & exit /b %RES_ERROR%
