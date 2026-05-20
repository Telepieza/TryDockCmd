@echo off
:: ===============================================================================
:: PROGRAM:   install.modules.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.1.30
:: DATE:      20/05/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Install modulos y paquetes version 7 y 8
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: Analiza si la llamada es del tcd.bat
set "proyecto=%~1"
set "log_action=!LOG-INFO!"
set /a "wait_timemod=10"
set "file_lang_tmp=%DIR_TMP%\trytond_modules"

call "%DIR_SCRIPT%install_header.bat" "%proyecto%" "%ins_lang_action%" "%MODU%" "install_modules"
if %ERRORLEVEL% NEQ 0 goto :exit
set "TRYTON_BRANCH=!CURRENT_VERSION:~0,3!"
call :logger "%APP%" "install_modules !WORD_VERSION!:[!CURRENT_VERSION!]" 

:menu_modules 
  set "option="
  set "MESSAGE="
  set "confirm="
  set "MODE="
  if /i "!TRYTON_LANGUAGE!"=="es" call :menu_es
  if /i "!TRYTON_LANGUAGE!"=="fr" call :menu_fr
  if /i "!TRYTON_LANGUAGE!"=="de" call :menu_de
  exit /b

:menu_es
  call :menu_header
  call :logger "%MENU%" "7. !INSTALL_MODU_PARS01!!TRYTON_BRANCH!" "5"
  call :logger "%INFO%" "!INSTALL_MODU_PARR04!" "7"
  call :logger "%MENU%" "8. !INSTALL_MODU_PARS02!!TRYTON_BRANCH!" "5"
  call :logger "%MENU%" "9. !INSTALL_MODU_PARS03!!TRYTON_BRANCH!" "5"  
  call :menu_foot
  goto :menu_modul

:menu_fr
  call :menu_header  
  call :menu_foot
  goto :menu_modul

:menu_de
  call :menu_header  
  call :logger "%MENU%" "7. !INSTALL_MODU_PARD01! !TRYTON_BRANCH!" "5"
  call :menu_foot
  goto :menu_modul

:menu_header
  cls
  :: Banner
  call "%DIR_SCRIPT%banner.bat" %TRYTON%
  echo ==========================================================================================
  call :logger %MENU% "!INSTALL_MODU_PAQU00!!TRYTON_BRANCH!" "5"
  echo ==========================================================================================
  call :logger "%MENU%" "1. !INSTALL_MODU_PAQU01!" "5"
  call :logger "%MENU%" "2. !INSTALL_MODU_PAQU02!" "5"
  call :logger "%INFO%" "!INSTALL_MODU_PAQU02I!"   "7"
  call :logger "%MENU%" "3. !INSTALL_MODU_PAQU03!" "5"
  call :logger "%INFO%" "!INSTALL_MODU_PAQU03I!"   "7"
  call :logger "%MENU%" "4. !INSTALL_MODU_PAQU04!" "5"
  call :logger "%INFO%" "!INSTALL_MODU_PAQU04I!"   "7"
  call :logger "%MENU%" "5. !INSTALL_MODU_PAQU05!" "5"
  call :logger "%INFO%" "!INSTALL_MODU_PAQU05I!"   "7"
  call :logger "%MENU%" "6. !INSTALL_MODU_PAQU06!" "5"
  call :logger "%INFO%" "!INSTALL_MODU_PAQU06I!"   "7"
  echo --------------------------------------------------------------------------------------------
  call :logger "%INFO%" "!INSTALL_MODU_PARR02!"    "7"
  call :logger "%INFO%" "!INSTALL_MODU_PARR03!"    "7"
  echo --------------------------------------------------------------------------------------------
  exit /b

:menu_foot
  call :logger "%MENU%" "Q. !INSTALL_MODU_PARF01!" "5"
  echo ==========================================================================================
  call :logger "%INFO%" "!INSTALL_MODU_PARF02!"    "2"
  echo.
  exit /b

:menu_modul
  set /p "option=%BS%        !C_M_YELLOW!%SELECT_OPT%!C_M_RESET! "
  if /i "%option%"=="Q" goto :exit
  if /i "%option%"=="1" set "MODE=1.- %INSTALL_MODU_PAQU01%"&& goto :confirm_option
  if /i "%option%"=="2" set "MODE=2.- %INSTALL_MODU_PAQU02%"&& goto :confirm_option
  if /i "%option%"=="3" set "MODE=3.- %INSTALL_MODU_PAQU03%"&& goto :confirm_option
  if /i "%option%"=="4" set "MODE=4.- %INSTALL_MODU_PAQU04%"&& goto :confirm_option
  if /i "%option%"=="5" set "MODE=5.- %INSTALL_MODU_PAQU05%"&& goto :confirm_option
  if /i "%option%"=="6" set "MODE=6.- %INSTALL_MODU_PAQU06%"&& goto :confirm_option
  if /i "%option%"=="7" set "MODE=7"&& goto :confirm_option
  if /i "%option%"=="8" set "MODE=8"&& goto :confirm_option
  if /i "%option%"=="9" set "MODE=9"&& goto :confirm_option
  call :logger "!LOG-WARN!" "!BCK_ERR_OPT!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "5" "1" "N"
  goto :menu_modules 

:confirm_option
  if /i "%MODE%"=="7" (
    if /i "!TRYTON_LANGUAGE!"=="es" set "MODE=7.- !INSTALL_MODU_PARS01!!TRYTON_BRANCH!"
    if /i "!TRYTON_LANGUAGE!"=="de" set "MODE=7.- !INSTALL_MODU_PARD01!!TRYTON_BRANCH!"
  )
  if /i "%MODE%"=="8" (
     if /i "!TRYTON_LANGUAGE!"=="es" set "MODE=8.- !INSTALL_MODU_PARS02!!TRYTON_BRANCH!"
  )
  if /i "%MODE%"=="9" (
     if /i "!TRYTON_LANGUAGE!"=="es" set "MODE=9.- !INSTALL_MODU_PARS03!!TRYTON_BRANCH!"
  )
  
  call "%DIR_SCRIPT%global_routines.bat" "%TRYTON%" "fill_in_field" "%TXT%" "%MODE%" "3"

  set "confirm="
  set /p "confirm=%BS%        !C_M_GREEN!!INSTALL_EXITS!!C_M_RESET! "
  if /i "%confirm%" NEQ "YES" (
    echo.
    call :logger "!LOG-CANCEL!" "!LOG_INSTALL_CANCEL!"
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "%wait_timemod%" "1" "N"
    goto :menu_modules  
  )
  if /i "%option%"=="1" goto :modules_backup
  if /i "%option%"=="2" goto :install_git
  if /i "%option%"=="3" goto :install_signxml
  if /i "%option%"=="4" goto :install_xmlsig
  if /i "%option%"=="5" goto :install_jinja2
  if /i "%option%"=="6" goto :install_pyopensll
  if /i "%option%"=="7" goto :modules_option_facturae
  if /i "%option%"=="8" goto :modules_option_verifactu
  if /i "%option%"=="9" goto :modules_option_sii
  goto :menu_modules  

:modules_backup
  call "%DIR_SCRIPT%backup.bat" "%proyecto%" "%FULL%"
  pause & goto :menu_modules 

:install_git
  echo.
  :: Instalamos git para soportar todos los repositorios de NAN-tic
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "install_system_package" "git"
  echo.
  if %ERRORLEVEL% NEQ 0 ( 
    call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_PAQER1!"
  ) else (
    call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!INSTALL_MODU_PAQMS1!"
  )
  echo.
 :: Instalamos hg de mercurial para soportar todos los repositorios de la comunidad tryton
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "install_system_package" "mercurial"
  echo.
  if %ERRORLEVEL% NEQ 0 ( 
    call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_PAQER1!"
  ) else (
    call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!INSTALL_MODU_PAQMS1!"
  )
  echo.
  pause & goto :menu_modules

:install_signxml
  echo.
  :: Instalación silenciosa de dependencia signxml
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "install_python_deps" "signxml" "libxmlsec1-dev pkg-config"
  if %ERRORLEVEL% NEQ 0 ( 
    call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_PAQER1!"
  ) else (
    call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!INSTALL_MODU_PAQMS1!"
  )
  echo.
  pause & goto :menu_modules

  :install_xmlsig
  echo.
  :: Instalación silenciosa de dependencia xmlsig
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "install_python_deps" "xmlsig"
  if %ERRORLEVEL% NEQ 0 ( 
    call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_PAQER1!"
  ) else (
    call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!INSTALL_MODU_PAQMS1!"
  )
  echo.
  pause & goto :menu_modules

  :install_jinja2
  echo.
  :: Instalación silenciosa de dependencia jinja2
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "install_python_deps" "Jinja2" "" "jinja2"
  if %ERRORLEVEL% NEQ 0 ( 
    call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_PAQER1!"
  ) else (
    call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!INSTALL_MODU_PAQMS1!"
  )
  echo.
  pause & goto :menu_modules

:install_pyopensll
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "install_python_deps" "pyOpenSSL"
  if %ERRORLEVEL% NEQ 0 ( 
    call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_MODU_PAQER1!"
  ) else (
    call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "!INSTALL_MODU_PAQMS1!"
  )
  echo.
  pause & goto :menu_modules

:modules_option_facturae
  if /i "!TRYTON_LANGUAGE!"=="es"  (
    call "%DIR_SCRIPT%install_external.bat" "%proyecto%" "account_es_facturae" "%APP%" "%file_log%"  
  )
  if /i "!TRYTON_LANGUAGE!"=="de"  (
    call "%DIR_SCRIPT%install_external.bat" "%proyecto%" "account_de_skr03" "%APP%" "%file_log%"  
  )
  pause & goto :menu_modules

:modules_option_verifactu
  call "%DIR_SCRIPT%install_external.bat" "%proyecto%" "account_es_verifactu" "%APP%" "%file_log%"  
  pause & goto :menu_modules 

:modules_option_sii
  call "%DIR_SCRIPT%install_external.bat" "%proyecto%" "account_es_sii" "%APP%" "%file_log%"  
  pause & goto :menu_modules

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:exit
  endlocal
  exit /b 0
