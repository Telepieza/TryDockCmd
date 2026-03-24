@echo off
:: =====================================================================================
:: PROGRAM:   client.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      23/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Check http://localhost:8000
:: =====================================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: APP o INS (INSTALL)
set "proyecto=%~1"
set "cte_action=%~2"
set "log_action=!LOG-INFO!"
set "db_error=0"
set "LOAD_FILE=0"
set "protocol=http://"
set "web=localhost"
set "islocal=0"
:: Segundo nivel — Puerto a la escucha
set "attempts=0"
set "max_attempts=10"
set "wait_timecte=5"
set "port_published=%SERVER_PUBLISHED%"
:: Analiza si la llamada es del tcd.bat
call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call "%DIR_SCRIPT%message.bat" %APP% "client %cte_action%"
:: 1. Verificar existencia del proyecto tryton en docker
if /i "%cte_action%"=="%APP%" if /i "%CURRENT_TRYTON%"=="" if /i "%CURRENT_POSTGRES%"=="" (
  call "%DIR_SCRIPT%inspectdocker.bat" "%proyecto%" "%APP%"
  if %errorlevel% equ 2 (
     set "MESSAGE=!STAT_ERR_NOT_INSTALLED:PROYECTO=%proyecto%!"
     call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!MESSAGE!"
     goto :exit
  )
)
if /i "%cte_action%"=="%INS%" set "log_action=%INS%"
if /i "%SERVER_PORT_PUBLISHED%" NEQ "" set "port_published=%SERVER_PORT_PUBLISHED%"
set "MESSAGE=!INSTALL_PORT_1:CONEXION=%port_published%!"
call "%DIR_SCRIPT%message.bat" "!log_action!" "!MESSAGE!"
:wait_port
  netstat -ano | find ":%port_published% " | find "LISTENING" >nul
  if %errorlevel% == 0 goto :continue
  set /a attempts+=1
  if %attempts% GEQ %max_attempts% (
    set "MESSAGE=!INSTALL_PORT_2:CONEXION=%port_published%!"
    call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!MESSAGE!"
    goto :error
  )
  set "MESSAGE=!INSTALL_PORT_3:CONEXION=%port_published%!"
  set "MESSAGE=!MESSAGE:COUNT=%attempts%!"
  call "%DIR_SCRIPT%message.bat" "!log_action!" "!MESSAGE!"
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timecte!" "1"
  goto :wait_port

:continue
  set "MESSAGE=!INSTALL_PORT_4:CONEXION=%port_published%!"
  call "%DIR_SCRIPT%message.bat" "!log_action!" "!MESSAGE!"
  where powershell.exe >nul 2>&1
 :: Cuarto nivel puerto abierto pero no activo
  if %errorlevel% == 0 (
    powershell -NoProfile -Command ^
    "$ProgressPreference='SilentlyContinue';" ^
    "try {" ^
    " Invoke-WebRequest 'http://localhost:8000' -UseBasicParsing -TimeoutSec 5 | Out-Null;" ^
    " exit 0 } catch { exit 1 }"
    if %errorlevel% NEQ 0 (
      call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "!INSTALL_HTTP!"
      goto :error
    )
  )

  set "url=%protocol%%web%:%port_published%"
  if not "%url:%web%=%"=="%url%" set "islocal=1"
  if "%islocal%"=="0" if not "%url:%ip%=%"=="%url%" set "islocal=1"
  set "MESSAGE=!INSTALL_PORT_5:CONEXION=%url%!"
  call "%DIR_SCRIPT%message.bat" "!log_action!" "!MESSAGE!"
  
  :: capa 5 (Si no es localhost se realiza un ping (Internet)
  if %islocal%=="0" (
     ping -n 1 8.8.8.8 >nul
     if %errorlevel% NEQ 0 (
       call "%DIR_SCRIPT%message.bat" "!LOG-WARN!" "!INSTALL_OFFLINE!"
       goto :error
     )
  )

:check_ready
  set /a "attempts+=1"
  call "%DIR_SCRIPT%message.bat" "!LOG-INFO!" "Checking service readiness (Attempt !attempts!/!max_attempts!)..."
  :: Intentamos hacer un 'ping' HTTP silencioso con PowerShell
  powershell -NoProfile -Command ^
   "$ProgressPreference='SilentlyContinue';" ^
   "try {" ^
   " $r = Invoke-WebRequest -Uri '%url%' -Method Head -TimeoutSec 2;" ^
   " exit 0 } catch { exit 1 }"

  if !errorlevel! equ 0 (
    call "%DIR_SCRIPT%message.bat" "!LOG-SUCC!" "Service is fully responsive. Launching browser..."
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timecte!" "1"
    start "" "%url%"
    goto :exit
  )
  if !attempts! LSS !max_attempts! (
    call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timecte!" "1"
    goto :check_ready
  ) else (
    call "%DIR_SCRIPT%message.bat" "!LOG-ERROR!" "Service is taking too long to respond. Please refresh manually."
  )
  goto :exit

:error
  endlocal
  exit /b 2

:exit
  endlocal
  exit /b 0

