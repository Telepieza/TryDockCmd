@echo off
:: ==============================================================================
:: PROGRAM:   startdocker.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      23/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Locate Docker and Start Up - Localizar Docker Desktop y arrancar 
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: 1. Verificación de seguridad (Acceso desde tcd.bat)
set "proyecto=%~1"
set /a "attempts=0"
set /a "max_attempts=10"
set /a "wait_timedok=3"
call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call :logger "%APP%" "startdocker"
:: Se han realizado muchas pruebas para localizar el programa Docker Desktop.exe. Se ha intentado localizar por el regedit o path , pero ninguno de los dos es 100% fiable.
:: Por supuesto existen dos formas más de localizar la ruta Docker Desktop.exe, siendo el protocolo de Windows o la ruta por defecto o protocolo URI.
:: La primera busqueda para localizar el programa Docker Desktop.exe es buscando el icono Docker en el escritorio por usuario o por el escritorio publico.
:: 3. Intentar localizar Docker Desktop vía Acceso Directo. Los ficheros .lnk son binarios, y es necesario llamar a powerShell para extraer la ruta del programa Docker Desktop.exe
: banner
call "%DIR_SCRIPT%banner.bat" "%proyecto%"
call :logger "!LOG-INFO!" "!DKR_STARTING!"
set "icono_docker=%USERPROFILE%\Desktop\Docker Desktop.lnk"
if not exist "%icono_docker%" set "icono_docker=%PUBLIC%\Desktop\Docker Desktop.lnk"
:: Si tenemos el icono y fichero .lnk, llamamos a powershell para que nos coloque en la variable docker_exe la ruta del programa Docker Desktop.exe
set "docker_exe="
if exist "%icono_docker%" (
    :: Usamos PowerShell para extraer la ruta. Limpiamos espacios y saltos de línea.
    for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command "$sh = New-Object -ComObject WScript.Shell; $sh.CreateShortcut('%icono_docker%').TargetPath"`) do set "docker_exe=%%p"
)
:: Si no tenemos docker_exe, por lo general la instalación de docker se encuenta en la ruta Program Files, se intenta dicha vía para localizar el programa Docker Desktop.exe.
:: 4. Si falla la búsqueda por .lnk, usamos ruta por defecto o protocolo URI
if "!docker_exe!"=="" set "docker_exe=C:\Program Files\Docker\Docker\Docker Desktop.exe"
:: Si existe el programa Docker Desktop.exe en la ruta localizada, se arranca, pero si no es encontrado, probamos con el protocolo Windows.
if exist "!docker_exe!" (
    start "" "!docker_exe!"
) else (
    :: Si no encontramos el .exe, intentamos abrirlo por el protocolo de Windows
    start "" "docker-desktop://"
)
:: Cada ordenador necesita su tiempo en arrancar docker una vez encontrado, por dicho motivo, se realiza un bucle de comprobación de hasta 10 attempts para analizar si responde.
:: 5. wait_docker de espera (Polling)

:wait_docker
  :: Usamos 'docker info' porque 'version' puede responder antes de que el motor esté listo
  docker info >nul 2>&1
  if %errorlevel% equ 0 (
    echo.
    call :logger "!LOG-SUCC!" "!DKR_READY!"
    goto :exit
  )
  if %attempts% GEQ %max_attempts% (
    echo.
    set "MESSAGE=!DKR_NOT_ENGINE:COUNT=%attempts%!"
    call :logger "!LOG-ERROR!" "!MESSAGE!"
    endlocal
    exit /b 1
  ) 
  <nul set /p=. 
  set /a attempts+=1
  call "%DIR_SCRIPT%global_routines.bat" "%proyecto%" "timeout_start" "!wait_timedok!" "1"
  goto :wait_docker

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2"
  exit /b

:exit
  endlocal
  exit /b 0