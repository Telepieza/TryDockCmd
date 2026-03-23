@echo off
:: ===============================================================================
:: PROGRAM:   global_routines.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      23/03/2026
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

:: Analiza si la llamada es del tcd.bat
call "%DIR_SCRIPT%startcontrol.bat" "%proyecto%"
call :logger "%APP%" "global_routines !glo_action! !param1! !param2!"
:: Se puede simplificar mucho la llamada a las diferentes subrutinas, pero me gusta más como lo he dejado.
:: el ejemplo de simplificacion es quitar todos los if y dejar call :%glo_action% "!param1!" "!param2!" "!param3!" "!param4!"
if /i "%glo_action%" == "timeout_start" (
    call :%glo_action% "!param1!" "!param2!" "!param3!"
    goto :exit
)
if /i "%glo_action%" == "fill_in_field" (
    call :%glo_action% "!param1!" "!param2!" "!param3!" "!param4!"
    goto :exit
)
if /i "%glo_action%" == "display_file_event_all" (
    call :%glo_action% "!param1!" "!param2!"
    goto :exit
)

if /i "%glo_action%" == "trytond_services" (
    call :%glo_action% "!param1!" "!param2!" "!param3!" "!param4!" "!param5!" "!param6!" "!param7!"
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
  :: Se indica expresemente no sacar la barra de puntos.
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
  call :logger "%fil_action%" "%text%" "%numer%"
  if /i "%file_cab%" NEQ "" echo # %text% >> "%file_cab%"
  call :logger "%MENU%" "%MESSAGE%" "%numer%"
  if /i "%file_cab%" NEQ "" echo # %MESSAGE% >> "%file_cab%"
  echo.
  exit /b

: Recibe un fichero, lo lee y es visualizado por consola y grabado en el fichero de log
:display_file_event_all
  set "event=%~1"
  set "file_temp=%~2"
  :: 1. Validar que el archivo existe y no está vacío
  if not exist "%file_temp%" exit /b
  :: 2. Recorre cada línea completa del fichero
  for /F "usebackq delims=" %%L in ("%file_temp%") do (
    if "%%L" NEQ "" (
      echo [%event%] %%L >nul
      call :logger "%event%" "!WORD_MESSAGE! %%L"
    )
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
   set "servicio=%~1"
   set "cmd=%~2"
   set "db_postgres=%~3"
   set "logfile=%~4"
   set "errfile=%~5"
   set "add=%~6"
   set "label=%~7"

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
  if "%label%" NEQ "" call :logger "%CHECK%" "!WORD_MESSAGE! !glo_action! %label%"
  if %status% EQU 0 if /i "%ins_tryton_action%" EQU "%INS%" call :timeout_start "10" "1"
  if %status% NEQ 0 (
     if exist "%errfile%" if not "%errfile%"=="" call :display_file_event_all "!LOG-ERROR!" "%errfile%"
     if exist "%logfile%" if not "%logfile%"=="" call :display_file_event_all "!LOG-INFO!" "%logfile%"
     exit /b %status%
  )
  exit /b 0

:logger
  call "%DIR_SCRIPT%message.bat" "%~1" "%~2" "%~3"
  exit /b

:exit
  endlocal
  exit /b 0
