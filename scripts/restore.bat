@echo off
REM ===============================================================================
REM PROGRAM:   restore.bat
REM PROJECT:   Tryton Docker Manager
REM AUTHOR: Telepieza
REM COLLABORATOR: Gemini (Google AI)
REM VERSION:   1.0.0
REM DATE:      23/03/2026
REM LICENSE:   MIT License
REM DESCRIPTION: Database Hot-Import - Main Menu (RESTORE)
REM ==============================================================================
setlocal enabledelayedexpansion
chcp 65001 >nul
set "proyecto=%~1"
set "base_backup_dir=%~2"
set /a "wait_timeres=10"
set "contdown=0"
call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call :logger "%APP%" "restore"

set "temp_title=!RES_PROCESS:PROYECTO=%MENU_TRYDOCK%!"
set "value_title=!temp_title! %TRYTON%:[%CURRENT_VER_MENU%] - [%CURRENT_PG_VERSION%]"
call :logger "%MENU%" "[+] 1.- !value_title!" "3"
call :logger "%MENU%" "[+] 2.- !BCK_DEST:PROYECTO=%DIR_RESTORE%!" "3"
call :logger "%MENU%" "[+] 3.- !BCK_CHECK:PROYECTO=%proyecto%!" "3"
call "%DIR_SCRIPT%status.bat" "%proyecto%" "%SQL%"
if %errorlevel% EQU 0 goto :menu_restore
set "contdown=1" 
set "MESSAGE=!BCK_CONT_STOP:PROYECTO=%POSTGRES%!"
call :logger "%MENU%" "3.1.- !MESSAGE!" "3"
set "MESSAGE=!BCK_STARTING:PROYECTO=%POSTGRES%!"
call :logger "%MENU%" "3.2.- !MESSAGE!" "3"
call "%DIR_SCRIPT%startup.bat" %proyecto% "%SQL%"
if %errorlevel% EQU 4 (
  set "MESSAGE=!BCK_CONT_STOP:PROYECTO=%POSTGRES%!"
  call :logger "!LOG-ERROR!" "!MESSAGE!"
  goto :exit
)
echo.

:menu_restore
  set "type="
  set "MESSAGE=!DB_NAME! - !DB_NAME_DEMO!"
  echo     ==========================================================================
  call :logger "%MENU%" "!value_title!" "10"
  echo     ==========================================================================
  echo.
  call :logger "!MENU!" "!RES_MENU_TITLE!" "5"
  echo.
  call :logger "!MENU!" "!RES_OPT1!" "5"
  call :logger "!MENU!" "!RES_OPT2!" "5" 
  call :logger "!MENU!" "!RES_OPT3:PROYECTO=%MESSAGE%!" "5"
  call :logger "!MENU!" "!RES_OPT4:PROYECTO=%MESSAGE%!" "5"
  call :logger "!MENU!" "!RES_OPT5:PROYECTO=%MESSAGE%!" "5"
  call :logger "!MENU!" "!RES_OPT6!" "5"
  echo.
  call :logger "%MENU%" "!RES_WARN!" "5"
  echo.
  set /p "type=%BS%        !C_M_YELLOW!!RES_PROMPT!!C_M_RESET! "
  echo.
  if "%type%"=="1" set DO_MODE=dumpall&& goto :image_restore
  if "%type%"=="2" set DO_MODE=dumpall&& goto :no_image_restore
  if "%type%"=="3" set DO_MODE=schema&& goto :schema_data_restore
  if "%type%"=="4" set DO_MODE=data&& goto :schema_data_restore
  if "%type%"=="5" set DO_MODE=full_db&& goto :schema_data_restore
  if "%type%"=="6" goto :end_restore
  call :logger !LOG-ERROR! "!RES_ERR_OPT!"
  goto :menu_restore

:image_restore
  set "DO_IMAGES=1"
  call "%DIR_SCRIPT%restore_unzip.bat" "%proyecto%" "%base_backup_dir%" "%DO_IMAGES%" "%DO_MODE%"
  goto :menu_restore

:no_image_restore
  set "DO_IMAGES=0"
  call "%DIR_SCRIPT%restore_unzip.bat" "%proyecto%" "%base_backup_dir%" "%DO_IMAGES%" "%DO_MODE%"
  goto :menu_restore

:schema_data_restore
  set "DO_IMAGES=2"
  echo %DO_MODE%
  call "%DIR_SCRIPT%restore_unzip.bat" "%proyecto%" "%base_backup_dir%" "%DO_IMAGES%" "%DO_MODE%"
  goto :menu_restore

:end_restore
   if "%contdown%"=="1" (
    call :logger "!log_action!" "!BCK_RESTORE_STATE!"
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
    call "%DIR_SCRIPT%startdown.bat" "%proyecto%" "%CHECK%" "STOP"
  )

  goto :exit

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:exit
  endlocal
  exit /b 0
