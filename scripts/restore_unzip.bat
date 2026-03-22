@echo off
:: ===============================================================================
:: PROGRAM:   restore_unzip.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      23/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Database Hot-Import - Unzip the files and folder.
:: ==============================================================================
setlocal enabledelayedexpansion
chcp 65001 >nul
set "proyecto=%~1"
set "BASE_BACKUP_DIR=%~2"
set "DO_IMAGES=%~3"
set "DO_MODE=%~4"
set /a "wait_timeres=10"

set /a "num_error=0"
set "ZIP_PATH="
set "DUMPALL_FILE="
call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call :logger "%APP%" "restore_unzip"

if not exist "%BASE_BACKUP_DIR%\*.zip" (
  set "MESSAGE=!RES_ERR_ZIP! %BASE_BACKUP_DIR%"
  call :logger "%LOG-ERROR%" "!MESSAGE!" "5"
  goto :error
)

call :logger "%MENU%" "===============================================================================" "5"
call :logger "%MENU%" "!RES_LIST_ZIP:DIRECTORY=%BASE_BACKUP_DIR%!" "5"
call :logger "%MENU%" "===============================================================================" "5"
echo.
set "work_mode=%TRYTON%_"
if /i "%DO_IMAGES%" EQU "2" set "work_mode=%work_mode%*%DO_MODE%"
if /i "%DO_IMAGES%" NEQ "2" set "work_mode=%work_mode%2"
set "work_mode=%work_mode%*.zip"
call :logger !LOG-INFO! "!RES_SEACH_ZIP! %BASE_BACKUP_DIR%\%work_mode%"
echo.
if exist "%BASE_BACKUP_DIR%\%work_mode%" dir "%BASE_BACKUP_DIR%\%work_mode%" /b
echo.
:other_file_zip
  echo.
  set "LOAD_FILE=0"
  set "zip_name="
  set "confirm="
  set "MESSAGE="
  set /p "zip_name=%BS%        !C_M_GREEN!!RES_ZIP_PROMPT!!C_M_RESET!"
  if /i "!zip_name!"=="" (
    set "MESSAGE=!RES_REQUIRED_FIELD!"
    set "LOAD_FILE=1"
  )
  if "!LOAD_FILE!" EQU "0" (
    set "ZIP_PATH=%BASE_BACKUP_DIR%\!zip_name!"
    if not exist "!ZIP_PATH!" (
      set "MESSAGE=!RES_ERR_ZIP! !ZIP_PATH!"
      set "LOAD_FILE=1"
    )
  )

 if /i "!LOAD_FILE!" EQU "1" (
   echo.
   call :logger "%LOG-ERROR%" "!MESSAGE!" "5"
   echo.
   set /p "confirm=%BS%        !C_M_GREEN!!RES_ZIP_REPEAT!!C_M_RESET! "
   if /i "!confirm!"=="YES" goto :other_file_zip
   set "LOAD_FILE=0"
   goto :exit
 )

 for %%A in ("%ZIP_PATH%") do set "ZIP_BASE=%%~nA"
 set "RESTORE_PATH=%DIR_RESTORE%\%ZIP_BASE%"
 if exist "%RESTORE_PATH%" rd /s /q "%RESTORE_PATH%" >nul 2>&1
 mkdir "%RESTORE_PATH%" >nul 2>&1
 set "MESSAGE=!RES_EXTRACT! !ZIP_PATH! to !RESTORE_PATH!"
 call :logger "!LOG-INFO!" "!MESSAGE!"
 if exist "%RESTORE_PATH%\%ZIP_BASE%" (
    set "BACKUP_PATH=%RESTORE_PATH%\%ZIP_BASE%"
 ) else (
    set "BACKUP_PATH=%RESTORE_PATH%"
 )

powershell -Command "$ProgressPreference='SilentlyContinue'; Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%RESTORE_PATH%' -Force"
if %errorlevel% NEQ 0 (
   set "MESSAGE=!RES_ERR_CMD! Expand-Archive"
   goto :error
)
 call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timeres!" "1"
if exist "%RESTORE_PATH%\%ZIP_BASE%" (
   set "BACKUP_PATH=%RESTORE_PATH%\%ZIP_BASE%"
) else (
   set "BACKUP_PATH=%RESTORE_PATH%"
)

if not exist "%BACKUP_PATH%" (
    set "MESSAGE=!RES_ERR_DIR! %BACKUP_PATH%"
    goto :error
)

set "work_mode=%BACKUP_PATH%\%TRYTON%_*%DO_MODE%.sql"
call :logger !LOG-INFO! "!RES_VALIDATE_ZIP! !work_mode!"
for %%F in ("%work_mode%") do set "DUMPALL_FILE=%%F"
if not defined DUMPALL_FILE (
   set "MESSAGE=!RES_REQUIRED_MISSING! %work_mode%" 
   goto :error
)

if not exist "%DUMPALL_FILE%" (
   set "MESSAGE=!RES_SRC_NOT_FOUND! %DUMPALL_FILE%"
   goto :error
)

for %%A in ("%DUMPALL_FILE%") do set "size=%%~zA"
if %size% LSS 1024 (
  set "MESSAGE=!RES_FILE_EMPTY! !DUMPALL_FILE!"
  goto :error
)

if /i "%DO_IMAGES%" NEQ "2" (
  set "work_dir=!BACKUP_PATH!\trytond"
  call :logger !LOG-INFO! "!RES_VALIDATE_ZIP! !work_dir!"
  if not exist "!work_dir!" (
    set "MESSAGE=!RES_REQUIRED_MISSING! !work_dir!"
    goto :error 
  )
)

if "%DO_IMAGES%"=="1" (
   set "work_tar=!BACKUP_PATH!\img_postgres.tar"
   call :logger !LOG-INFO! "!RES_VALIDATE_ZIP! !work_tar!"
   if not exist "!work_tar!" (
      set "MESSAGE=!RES_REQUIRED_MISSING! !work_tar!"
      goto :error
   )
   set "work_tar=!BACKUP_PATH!\img_tryton.tar"
   call :logger !LOG-INFO! "!RES_VALIDATE_ZIP! !work_tar!"
   if not exist "!work_tar!" (
    set "MESSAGE=!RES_REQUIRED_MISSING! !work_tar!"
    goto :error
  )
)

if /i "%DO_IMAGES%" NEQ "2" (
  call "%DIR_SCRIPT%restore_docker.bat" "%proyecto%" "%BACKUP_PATH%" "%DO_IMAGES%" "%DUMPALL_FILE%"
) else (
  call "%DIR_SCRIPT%restore_sql.bat" "%proyecto%" "%BACKUP_PATH%" "%DO_IMAGES%" "%DUMPALL_FILE%" "%DO_MODE%"
)

if "%errorlevel%" NEQ 0 goto :exit
echo.
goto:exit

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:error
  echo.
  call :logger "!LOG-ERROR!" "!MESSAGE!"
  echo.
  pause 
  if exist "%RESTORE_PATH%" rd /s /q "%RESTORE_PATH%" >nul 2>&1
  endlocal
  exit /b 1

:exit
  if exist "%RESTORE_PATH%" rd /s /q "%RESTORE_PATH%" >nul 2>&1
  endlocal
  exit /b 0