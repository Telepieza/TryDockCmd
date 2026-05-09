@echo off
:: ===============================================================================
:: PROGRAM:   global_routines.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini Code Assist
:: VERSION:   1.1.26
:: DATE:      10/05/2026
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
if /i "%glo_action%" == "timeout_start" (
    call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!] [!param2!] [!param3!]"
    call :%glo_action% "!param1!" "!param2!" "!param3!"
    goto :exit
)
if /i "%glo_action%" == "fill_in_field" (
    call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!] [!param2!] [!param3!] [!param4!]"
    call :%glo_action% "!param1!" "!param2!" "!param3!" "!param4!"
    goto :exit
)
if /i "%glo_action%" == "display_file_event_all" (
    call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!] [!param2!]"
    call :%glo_action% "!param1!" "!param2!"
    goto :exit
)
if /i "%glo_action%" == "install_python_deps" (
    call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!] [!param2!]"
    call :%glo_action% "!param1!" "!param2!"
    goto :exit
)
if /i "%glo_action%" == "check_system_version" (
    call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action!"
    call :%glo_action%
    goto :exit
)
if /i "%glo_action%" == "audit_xml_models" (
    call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!]"
    call :%glo_action% "!param1!"
    goto :exit
)
if /i "%glo_action%" == "fix_xml_models" (
    call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!]"
    call :%glo_action% "!param1!"
    goto :exit
)

if /i "%glo_action%" == "trytond_services" (
    call "%DIR_SCRIPT%message.bat" "%APP%" "global_routines !glo_action! [!param1!] [!param2!] [!param3!] [!param4!] [!param5!] [!param6!] [!param7!] [!param8!]"
    call :%glo_action% "!param1!" "!param2!" "!param3!" "!param4!" "!param5!" "!param6!" "!param7!" "!param8!"
    goto :exit
)

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
  for /F "usebackq delims=" %%L in ("%file_temp%") do (
    set "clean_line=%%L"
    set "event_now=!event_default_file!"

    :: Analizar contenido de la línea para ajustar el color dinámicamente
    echo "!clean_line!" | findstr /I "INFO NATIVO" >nul
    if !errorlevel! EQU 0 set "event_now=!LOG-INFO!"

    echo "!clean_line!" | findstr /I "ERROR Traceback AttributeError ValueError ParsingError" >nul
    if !errorlevel! EQU 0 set "event_now=!LOG-ERROR!"

    echo "!clean_line!" | findstr /I "EXTERNO" >nul
    if !errorlevel! EQU 0 set "event_now=!LOG-WARN!"

    :: Limpiar caracteres que rompen el comando message.bat
    set "clean_line=!clean_line:)=]!"
    set "clean_line=!clean_line:(=[!"
    set "clean_line=!clean_line:<=]!"
    set "clean_line=!clean_line:>=[!"
    set "clean_line=!clean_line:^&=y!"
    set "clean_line=!clean_line:"=!"
    
    call "%DIR_SCRIPT%message.bat" "!event_now!" "!WORD_MESSAGE! !clean_line!"
  )
  exit /b

:audit_xml_models
  set "folder=%~1"
  call "%DIR_SCRIPT%message.bat" "%CHECK%" "Auditoría XML: Buscando campos 'model' con 'ref' para revertir en !folder!..."
  set "found_err=0"
  for /r "!folder!" %%f in (*.xml) do (
      findstr /I "name=\"model\"" "%%f" | findstr /I "ref=" >nul
      if !errorlevel! EQU 0 (
          set "found_err=1"
          call "%DIR_SCRIPT%message.bat" "!LOG-WARN!" "Sintaxis 'ref' detectada (necesita revertir a search) en: %%f"
          findstr /n /I "name=\"model\"" "%%f" | findstr /I "ref="
      )
  )
  if "!found_err!"=="0" call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "No se encontraron conflictos en los XML."
  exit /b !found_err!

:fix_xml_models
  set "folder=%~1"
  call "%DIR_SCRIPT%message.bat" "%CHECK%" "Iniciando corrección automática de XML en !folder!..."
  :: Ejecuta PowerShell para realizar el reemplazo por Regex en todos los XML de la carpeta
  powershell -Command ^
    "Get-ChildItem -Path '!folder!' -Filter *.xml -Recurse | ForEach-Object { ^
        $content = Get-Content $_.FullName -Raw; ^
        $newContent = [regex]::Replace($content, 'ref=\"model_(?<model>[^\"\s]+)\"', { ^
            param($m) 'search=\"[(''model'', ''='', ''' + ($m.Groups['model'].Value -replace '_', '.') + ''')]\"' ^
        }); ^
        if ($content -ne $newContent) { ^
            $newContent | Set-Content $_.FullName -Encoding UTF8; ^
            Write-Host 'Revertido a search: ' $_.FullName ^
        } ^
    }"
  call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "Proceso de corrección finalizado."
  exit /b

:check_system_version
  echo.
  call "%DIR_SCRIPT%message.bat" "%CHECK%" "--- AUDITORIA DE SISTEMA ---"
  docker exec "!CURRENT_TRYTON!" trytond-admin --version > "%TEMP%\t_ver.txt" 2>&1
  set /p v_real=<"%TEMP%\t_ver.txt"
  call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "Versión Real en Contenedor: !v_real!"
  exit /b

:install_python_deps
  REM %1 = paquete pip
  REM %2 = dependencias apt (opcional)
  set "package=%~1"
  set "check_import=%~1"
  :: Casos especiales donde el nombre del paquete pip != nombre de importación
  if /i "%package%" == "pyOpenSSL" set "check_import=OpenSSL"
  set "sys_deps=%~2"
  :: 1. Comprobar si el paquete ya está instalado en el contenedor
  docker exec -u 0 "!CURRENT_TRYTON!" bash -c "python3 -c \"import !check_import!\"" >nul 2>&1
  if !errorlevel! EQU 0 (
    call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!WORD_MODULE! !package! ya está instalado en el contenedor."
    exit /b 0
  )

  :: 2. Si no está instalado, proceder con la instalación
  if "!sys_deps!" NEQ "" (
      docker exec -u 0 "!CURRENT_TRYTON!" bash -c "apt-get update && apt-get install -y !sys_deps! && pip install !package! --break-system-packages"
  ) else (
      docker exec -u 0 "!CURRENT_TRYTON!" bash -c "pip install !package! --break-system-packages"
  )
  exit /b

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
    docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%SERVER%" bash -c "%cmd%" %redir_out% %redir_err%
  )
  if /i "%servicio%"=="%POSTGRES%" (
    docker compose -f "%DIR_HOME%%COMPOSE_FILE%" -p "%proyecto%" exec -T "%POSTGRES%" psql -U postgres -d "%db_postgres%" -At -c "%cmd%" %redir_out% %redir_err%
  )
  set "status=%ERRORLEVEL%"
  if %status% EQU 0 (
    if /i "%ins_tryton_action%" EQU "%INS%" call :timeout_start "10" "1"
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
