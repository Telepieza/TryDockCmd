@echo off
:: ===============================================================================
:: PROGRAM:   install_report.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      23/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Install reports 
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: Analiza si la llamada es del tcd.bat
set "proyecto=%~1"
set "option=%~2"
set "cmd=%~3"
set "title=%~4"
set "numer=%~5"
set "file=%~6"
set "pdemo=%~7"

set "wfile_activ_list=%DIR_TMP%\trytond_activ"
set "wfile_modules_list=%DIR_TMP%\trytond_modules"
set "wfile_audit_list=%DIR_TMP%\trytond_audit"
set "wfile_table_list=%DIR_TMP%\trytond_table"

set "spaces=                                                               "
set "dots=................................................................."
set "cab1=---------------------------------------------------------------------------------"
set "cab2================================================================================="
set "cab4=-+-----------------------------------------------+-----------------+"

call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call "%DIR_SCRIPT%message.bat" "%APP%" "install_reports [!option!] - !cmd! - !title! - [!file!] - [!pdemo!]"
set "idate_rts=%date%" & call "%DIR_SCRIPT%cycletime.bat" "%DAT%" "%idate_rts%" & set "idate_rts_fmt=!fmt_ddmmyyyy!"
set "itime_rts=%time%" & call "%DIR_SCRIPT%cycletime.bat" "%TIM%" "%itime_rts%" & set "itime_rts_fmt=!fmt_hhmmss!"

call "%DIR_SCRIPT%message.bat" "%CHECK%" "!INSTALL_MODU_35!"
call "%DIR_SCRIPT%base_modules.bat" "%proyecto%"

set "sufijo="
if /i "%pdemo%"=="!DEMO!" set "sufijo=_demo"
if /i "%pdemo%"=="!LANG!" set "sufijo=_lang"
set "file_activ_list=%wfile_activ_list%%sufijo%_list%EXT_TXT%"
set "file_modules_list=%wfile_modules_list%%sufijo%_list%EXT_TXT%"
set "file_audit_list=%wfile_audit_list%%sufijo%_list%EXT_TXT%"

if /i "%option%"== "1" (
  set  "file_table_list=%wfile_table_list%%sufijo%%cmd%_list%EXT_TXT%"
  call :head_report "!title!" "!file_table_list!"
  call :format_pg_table "!cmd!" "!title!" "!numer!" "!file!"
  call :foot_report "!file_table_list!"
  exit /b
)  

if /i "%option%"== "7" (
  call :head_report "!title!" "!file_audit_list!"
  call :extract_xml_from_log_moduls "!cmd!" "!title!" "!numer!" "!file!"
  call :foot_report "!file_audit_list!"
  type "!file_audit_list!"
  exit /b
)
:: Comprende opciones 8
if /i "%option%"== "8" (
  call :head_report "!title!" "!file_modules_list!"
  call :listing_modules "!cmd!" "!title!" "!numer!" "!file!"
  call :foot_report "!file_modules_list!"
  exit /b
)  

:: Comprende opciones 5
if /i "%option%"== "5" (
  call :head_report "!title!" "!file_activ_list!"
  call :compare_modules_lang "!cmd!" "!title!" "!numer!" "!file!"
  call :foot_report "!file_activ_list!"
  exit /b
)  

:: Comprende opciones 6
if /i "%option%"== "6" (
  call :head_report "!title!" "!file_activ_list!"
  call :compare_modules_demo "!cmd!" "!title!" "!numer!" "!file!"
  call :foot_report "!file_activ_list!"
  exit /b
)  

:: Comprende opciones 9
if /i "%option%"== "9" (
  call :head_report "!title!" "!file_activ_list!"
  call :compare_modules "!cmd!" "!title!" "!numer!" "!file!"
  call :foot_report "!file_activ_list!"
  exit /b
)  

:: 06
:listing_modules
  set "event=%~1"
  set "title=%~2"
  set "numer=%~3"
  set "file_modules=%~4"
  set "last_prefix="
:: Definir ESC de forma limpia (funciona en Win 10/11)
  for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
  set "g_on=!ESC![92m"
  set "g_off=!ESC![0m"
  :: Estos anchos deben sumar lo mismo que tus guiones de la tabla
  set "w_mod=45"
  set "w_stat=15"
  set "w_statc=6"
  echo.
  call "%DIR_SCRIPT%message.bat" "!event!" "!title!" "!numer!"
 :: Dibujo de cabecera (Ajustado a 35 + 15 caracteres + márgenes)
  echo !cab4! & echo !cab4! >> "%file_modules_list%"
  set "h1=!WORD_NAME!!spaces!"
  set "h2=!WORD_STATUS!!spaces!"
  set "cab3=^| !h1:~0,%w_mod%! ^| !h2:~0,%w_stat%! ^|"
  echo  ^| !h1:~0,%w_mod%! ^| !h2:~0,%w_stat%! ^|
  echo -^| !h1:~0,%w_mod%! ^| !h2:~0,%w_stat%! ^| >> "%file_modules_list%"
  echo !cab4! & echo !cab4! >> "%file_modules_list%"
  for /f "usebackq tokens=1,2 delims=|" %%a in (%file_modules%) do (
      set "full_name=%%a"
      set "status=%%b"     
      :: 1. Extraer prefijo para la lógica de árbol
      for /f "tokens=1 delims=_" %%p in ("%%a") do set "current_prefix=%%p"
      :: 2. Definir texto de la primera columna (con árbol)
      set "mod_display=%%a"
      if "!current_prefix!"=="!last_prefix!" (
          set "mod_display=   +-- %%a"
      ) else (
          set "last_prefix=!current_prefix!"
      )
      :: 3. Aplicar puntos de guía (dots) y recortar a w_mod
      set "v_mod=!mod_display!!dots!"
      set "mod_fmt=!v_mod:~0,%w_mod%!"
      :: 4. Aplicar color al estado sin romper la alineación
      if /i "!status!"=="activated" (
          :: Usamos la palabra limpia para calcular el relleno sobrante
          set "temp_stat=activated!spaces!"
          set "stat_fmt=!g_on!activated!g_off!!temp_stat:~9,%w_statc%!"
          set "staf_fmt=activated!temp_stat:~9,%w_statc%!"
      ) else (
          set "v_stat=!status!!spaces!"
          set "stat_fmt=!v_stat:~0,%w_stat%!"
          set "staf_fmt=!v_stat:~0,%w_stat%!"
      )
      :: 5. Imprimir línea de la tabla
      set "lin1=^| !mod_fmt! ^| !staf_fmt! ^|"
      echo  ^| !mod_fmt! ^| !stat_fmt! ^|
      echo !lin1! >> "%file_modules_list%"
      call "%DIR_SCRIPT%message.bat" "%CHECK%" "!lin1!"
  )
  :: Cierre de la tabla
  echo !cab4! & echo !cab4! >> "%file_modules_list%"
  echo.
exit /b
 
:: 01,02,03 (install_reports)
:format_pg_table
  set "event=%~1"
  set "text=%~2"
  set "numer=%~3"
  set "file_temp=%~4"
  :: --- Definir anchos de columna ---
  :: Ajustamos w_name un poco más para nombres de extensiones largos
  set "w_name=18"
  set "w_owner=15"
  set "w_code=8"
  set "w_ver=10"
  echo.
  if /i "%event%"=="L" (
    set "h1=!WORD_DATABASE!!spaces!"
    set "h2=!WORD_OWNER!!spaces!"
    set "h3=!WORD_ENCODING!!spaces!"
    call "%DIR_SCRIPT%message.bat" "!MENU!" "!text!" "5"
    set "cab3=!h1:~0,%w_name%! ^| !h2:~0,%w_owner%! ^| !h3:~0,%w_code%! ^| !WORD_COLLATION!"
    echo %cab1% & echo !cab3! & echo %cab1%
  ) else if /i "%event%"=="X" (
    :: Nueva sección para Extensiones
    set "h1=!WORD_EXTENSION!!spaces!"
    set "h2=!WORD_VERSION!!spaces!"
    call "%DIR_SCRIPT%message.bat" "!MENU!" "!text!" "5"
    set "cab3=!h1:~0,%w_name%! ^| !h2:~0,%w_ver%! ^| !WORD_DESCRIPTION!"
    echo %cab1% & echo !cab3! & echo %cab1%
  ) else (
    :: Por defecto para Usuarios (U)
    set "h1=!WORD_USER!!spaces!"
    call "%DIR_SCRIPT%message.bat" "!MENU!" "!text!" "5"
    set "cab3=!h1:~0,%w_name%! ^| !WORD_ATTRIBUTES!"
    echo %cab1% & echo !cab3! & echo %cab1%
  )

  ( echo %cab1% & echo # !cab3! & echo %cab1% ) >> "%file_table_list%"

  :: --- Procesamiento de Datos ---
 for /f "usebackq tokens=1-6 delims=|" %%a in ("%file_temp%") do (
    set "v_name=%%a!spaces!"
    set "name_fmt=!v_name:~0,%w_name%!"
    set "v_owner=%%b!spaces!"
    set "owner_fmt=!v_owner:~0,%w_owner%!"
    set "v_code=%%c!spaces!"
    set "code_fmt=!v_code:~0,%w_code%!"
    if /i "%event%"=="L" (
        echo %%a | findstr /v "=" >nul
        if !errorlevel! equ 0 (
          set "lin1=!name_fmt! ^| !owner_fmt! ^| !code_fmt! ^| %%e"
          echo !lin1! & echo !lin1! >> "%file_table_list%" & call "%DIR_SCRIPT%message.bat" "%CHECK%" "!lin1!"
        )
    ) else if /i "%event%"=="X" (
        :: Procesar Extensiones: %%a=Name, %%b=Version, %%c=Schema, %%d=Description
        set "v_ver=%%b!spaces!"
        set "ver_fmt=!v_ver:~0,%w_ver%!"
        set "lin1=!name_fmt! ^| !ver_fmt! ^| %%d"
        echo !lin1! & echo !lin1! >> "%file_table_list%" & call "%DIR_SCRIPT%message.bat" "%CHECK%" "!lin1!"
    ) else (
        set "lin1=!name_fmt! ^| %%b"
        echo !lin1! & echo !lin1! >> "%file_table_list%" & call "%DIR_SCRIPT%message.bat" "%CHECK%" "!lin1!"
    )
  )
  echo %cab1%
exit /b

:compare_modules
  set "action=%~1"
  set "text=%~2"
  set /a "numer=0"
  if /i "%~3" NEQ "" set /a "numer=%~3"
  set "file_activ=%~4"
  
  call "%DIR_SCRIPT%message.bat" "%action%" "%text%" "%numer%"

  :: C1=country currency company party bank
  call :compare_phase "C1" "%F1%" "%file_activ%"
  :: C2=product stock
  call :compare_phase "C2" "%F2%" "%file_activ%"
  :: C3=account account_eu account_product account_invoice account_invoice_stock account_payment
  call :compare_phase "C3" "%F3%" "%file_activ%"
  :: C4=sale purchase
  call :compare_phase "C4" "%F4%" "%file_activ%"
  :: C5=stock_supply purchase_request
  call :compare_phase "C5" "%F5%" "%file_activ%"
  :: C6=product_image product_attribute product_measurements product_price_list stock_lot
  call :compare_phase "C6" "%F6%" "%file_activ%" 
  :: C7=production production_routing production_work stock_supply_production project timesheet company_work_time carrier stock_shipment_cost 
  call :compare_phase "C7" "%F7%" "%file_activ%"
  :: C8=dashboard marketing party_relationship
  call :compare_phase "C8" "%F8%" "%file_activ%"
  :: Modulo del lenguaje seleccionado
  if /i "!LL!" NEQ "" (
    call :compare_phase "LL" "%LX%" "%file_activ%"
  )
exit /b

:compare_modules_demo
  set "action=%~1"
  set "text=%~2"
  set /a "numer=0"
  if /i "%~3" NEQ "" set /a "numer=%~3"
  set "file_activ=%~4"
  call "%DIR_SCRIPT%message.bat" "%action%" "%text%" "%numer%"
  :: D1=country currency company party bank
  call :compare_phase "D1" "%G1%" "%file_activ%"
  :: D2=product stock
  call :compare_phase "D2" "%G2%" "%file_activ%"
  :: D3=account account_payment account_product account_statement account_invoice account_invoice_stock
  call :compare_phase "D3" "%G3%" "%file_activ%"
  :: D4=sale purchase
  call :compare_phase "D4" "%G4%" "%file_activ%"
  :: D5=production production_work party_avatar company_work_time timesheet
  call :compare_phase "D5" "%G5%" "%file_activ%"
  :: D6=project
  call :compare_phase "D6" "%G6%" "%file_activ%"   
exit /b

:compare_modules_lang
  set "action=%~1"
  set "text=%~2"
  set /a "numer=0"
  if /i "%~3" NEQ "" set /a "numer=%~3"
  set "file_activ=%~4"
  call "%DIR_SCRIPT%message.bat" "%action%" "%text%" "%numer%"
  :: LL=Modulo del lenguaje seleccionado (es,fr,de)
  call :compare_phase "LL" "%LX%" "%file_activ%"
exit /b

:compare_phase
  set "phase_name=%~1"
  set "moduls_name=%~2"
  set "file_activ=%~3"
:: No tocar el codigo, es correcto
  set "phase_modules=!%phase_name%!"
  if not exist "%file_activ%" (
    set "MESSAGE=!INSTALL_MODU_FILE:FILE=%file_activ%!"
    call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!MESSAGE!"
    echo !LOG-ERROR! !MESSAGE! >> "%file_activ_list%"
    exit /b
  )
  set "moduls_text=!INSTALL_MODU_PHASES!:%moduls_name%"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "fill_in_field" "%MENU%" "!INSTALL_MODU_PHASES!:%moduls_name%" "2" "%file_activ_list%"
  for %%M in (!phase_modules!) do (
    set "found=0"
    for /f "tokens=*" %%A in (%file_activ%) do (
      if /i "%%A"=="%%M" set "found=1"
    )
    if "!found!"=="1" (
      set "lin1=!WORD_MESSAGE! !LOG-SUCC! !WORD_MODULE! %%M"
      echo !LOG-INFO! !lin1! >> "%file_activ_list%" & call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "!lin1!"  "2"
    )
    if "!found!"=="0" (
      set "lin1=!WORD_MESSAGE! !LOG-PENDING! !WORD_MODULE! %%M"
      echo !LOG-ALERT! !lin1! >> "%file_activ_list%" & call "%DIR_SCRIPT%message.bat" "!LOG-ALERT!" "!lin1!"
    )
  )
  exit /b

:extract_xml_from_log_moduls
  :: --------------------------------------------
  :: report_xml_by_module.bat - VERSION ESTABLE (SIN PARÉNTESIS CONFLICTIVOS)
  :: --------------------------------------------
  set "event=%~1"
  set "text=%~2"
  set "numer=%~3"
  set "FILE_XML_LOG=%~4"

  :: Capturar tiempo inicial
  set "STARTDATE=%date%"
  set "STARTTIME=%time%"
  if exist "%file_audit_list%" del "%file_audit_list%"
  ( echo %cab2% & echo !INSTALL_MODU_HEAD22! - !proyecto! & echo %cab2% ) >> "%file_audit_list%"

  set "current_mod="
  :: Leemos el log. Una sola pasada.
  for /f "usebackq tokens=7,9" %%M in ("%FILE_XML_LOG%") do (
    set "v_mod=%%M"
    set "v_file=%%N"
    
    :: Evitamos paréntesis usando saltos o líneas simples
    if /i "!v_mod!" neq "!current_mod!" (
        echo [ !WORD_MODULE!: !v_mod! ] >> "%file_audit_list%"
        echo %cab1% >> "%file_audit_list%"
        set "current_mod=!v_mod!"
    )

    :: CONSTRUIR RUTA DINÁMICA - Versión sin paréntesis para evitar errores
    set "fullpath="
    if /i "!v_mod!"=="ir"  set "fullpath=%BASE_I%/!v_file!"
    if /i "!v_mod!"=="res" set "fullpath=%BASE_R%/!v_file!"
    if not defined fullpath set "fullpath=%BASE_M%/!v_mod!/!v_file!"
    :: ANÁLISIS DIRECTO
    set "xml_type=!WORD_DATA!"
    :: 1. Comprobar si existe
    docker compose -p %proyecto% exec -T %SERVER% ls "!fullpath!" >nul 2>&1
    if !errorlevel! neq 0 (
        set "xml_type=!WORD_NOTFOUND!"
    ) else (
        :: 2. Si existe, buscamos el patrón (m 1 para velocidad)
        docker compose -p %proyecto% exec -T %SERVER% grep -m 1 -Eq "ir.ui.view|ir.action" "!fullpath!" >nul 2>&1
        if !errorlevel! equ 0 set "xml_type=!WORD_STRUCTURE!"
    )
    :: FORMATEO DE COLUMNAS
    set "file_fmt=!v_file!!spaces!"
    set "file_fmt=!file_fmt:~0,35!"
    echo   !file_fmt! !xml_type! >> "%file_audit_list%"
    call "%DIR_SCRIPT%message.bat" "%CHECK%" "!file_fmt! !xml_type!"
    echo [+] !WORD_PROCESSED!: !v_mod! / !v_file!
  )
  exit /b

:head_report
  set "text=%~1"
  set "file_head=%~2"
  if exist "%file_head%" del /q "%file_head%"
  ( echo !cab2!
    echo # !text! 
    echo !%cab2!
  ) > "%file_head%"
  exit /b    

:foot_report
   set "file_foot=%~1"
   set "aplication=%~2"
   set "count=0"
   :: - = # 
   for /f %%C in ('findstr /v /r "^= ^# ^-" "%file_foot%" ^| find /c /v ""') do set "count=%%C"
   set "count=%count: =%"
   call "%DIR_SCRIPT%cycletime.bat" "%DAT%" "%date%" & set "fdate_rts_fmt=!fmt_ddmmyyyy!"
   call "%DIR_SCRIPT%cycletime.bat" "%TIM%" "%time%" & set "ftime_rts_fmt=!fmt_hhmmss!"
   call "%DIR_SCRIPT%cycletime.bat" "%CALC%" "!itime_rts!" "%time%" & set "rtime_rts_fmt=!fmt_hhmmsscc!"
   set "trydockcmd=%APPLICATION% - !fdate_rts_fmt! !LENG_MSG! !rtime_rts_fmt!"
   echo.
   echo %cab2%  
   echo !INSTALL_MODU_FOOT04!: !rtime_rts_fmt!
   echo !INSTALL_MODU_FOOT05!: %count%
   echo !INSTALL_MODU_FOOT06!: %file_foot%
   echo %cab2%
   (
  ::el # del echo # es para que el findstr no cuente las líneas de cabecera y las del pie
   echo %cab1%
   echo # !INSTALL_MODU_FOOT01!:
   echo # !INSTALL_MODU_FOOT02!: !idate_rts_fmt! - !itime_rts_fmt!
   echo # !INSTALL_MODU_FOOT03!: !fdate_rts_fmt! - !ftime_rts_fmt!
   echo # !INSTALL_MODU_FOOT04!: !rtime_rts_fmt!
   echo # !INSTALL_MODU_FOOT05!: !count!
   echo %cab1%
  ) >> "%file_foot%"
  echo.
  exit /b

:exit
  endlocal
  exit /b 0
