@echo off
:: ==============================================================================
:: PROGRAM:   cycletime.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      23/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: cycletime (Calcula el tiempo entre horas o formatea la hora en HH MM SS)
:: ==============================================================================
REM %~1 = Accion "CALC", TIM (TIME), DAT (DATE)
REM %~2 = Hora Inicio para "CALC" y Hora a formatear para TIME
REM %~2 = Hora Final para "CALC"
REM %~2 = Fecha formato para "DAT"
set "cyc_action=%~1"
set "idatetime="
set "fdatetime="
if /i not "%~2"=="" set "idatetime=%~2"
if /i not "%~3"=="" set "fdatetime=%~3"
if /i "%cyc_action%" EQU "%DAT%" if /i "%~2"=="" set "idatetime=%date%"
if /i "%cyc_action%" NEQ "%DAT%" if /i "%~2"=="" set "idatetime=%time%"
set /a "duration_h=0"
set /a "duration_m=0"
set /a "duration_s=0"
set /a "duration_cc=0"
set /a "dia=0"
set /a "mes=0"
set /a "anio=0"
set /a "seconds=0"
set /a "centis=0"
set "fmt_hhmmss="
set "fmt_hhmmsscc="
set "fmt_ddmmyy="  
set "fmt_ddmmyyyy=" 
set "fmt_yyyymmdd=" 
set "fmt_yymmdd=" 
set "fmtf_yyyymmdd=" 
set "fmtf_yymmdd=" 

:: Se recupera el valor, por ejemplo dd/mm/yy !fmt_ddmmyy!
if /i "%cyc_action%"=="%DAT%" (
  for /f "tokens=1-3 delims=/ " %%a in ("%idatetime%") do (  set "dia=0%%a" & set "mes=0%%b" & set "anio=%%c"  )
  set "dia=!dia: =!" & set "dia=!dia:~-2!"
  set "mes=!mes: =!" & set "mes=!mes:~-2!"
  : Ejemplo: 13/02/2026
  set "fmt_ddmmyy=!dia!/!mes!/!anio:~-2!"  
  :: Ejemplo: 13/02/26 
  set "fmt_ddmmyyyy=!dia!/!mes!/!anio!"
  :: Ejemplo: 2026/02/13
  set "fmt_yyyymmdd=!anio!/!mes!/!dia!"
  :: Ejemplo: 26/02/13
  set "fmt_yymmdd=!anio:~-2!/!mes!/!dia!"
  :: Ejemplo: 20260213
  set "fmtf_yyyymmdd=!anio!!mes!!dia!"
  :: Ejemplo: 260213
  set "fmtf_yymmdd=!anio:~-2!!mes!!dia!"
  exit /b
)

if /i "%cyc_action%"=="%TIM%" (
  for /f "tokens=1-4 delims=:.," %%a in ("%idatetime%") do (
   set /a "duration_h=%%a, duration_m=1%%b-100, duration_s=1%%c-100, duration_cc=1%%d-100"
  )
  goto :fmt_time
)

:: Extraer horas, minutos, segundos y centésimas (Inicio)
for /f "tokens=1-4 delims=:.," %%a in ("%idatetime%") do (
   set /a "start_h=%%a, start_m=1%%b-100, start_s=1%%c-100, start_cc=1%%d-100"
)
:: Extraer horas, minutos, segundos y centésimas (Fin)
for /f "tokens=1-4 delims=:.," %%a in ("%fdatetime%") do (
   set /a "end_h=%%a, end_m=1%%b-100, end_s=1%%c-100, end_cc=1%%d-100"
)

:: Convertir todo a centésimas de segundo
set /a "start_total=(start_h*360000)+(start_m*6000)+(start_s*100)+start_cc"
set /a "end_total=(end_h*360000)+(end_m*6000)+(end_s*100)+end_cc"

:: Calcular la diferencia
set /a "diff=end_total-start_total"
:: Si el proceso pasó de medianoche, ajustamos
if %diff% lss 0 set /a "diff+=8640000"
:: === Extraer segundos enteros y centésimas ===
set /a "seconds = diff / 100"
set /a "centis = diff %% 100"
:: === Descomponer en H:M:S ===
set /a "duration_h = seconds / 3600"
set /a "duration_m = (seconds %% 3600) / 60"
set /a "duration_s = seconds %% 60"

:fmt_time
  :: === Formatear con ceros a la izquierda ===
  if %duration_h% LSS 10 set "duration_h=0%duration_h%"
  if %duration_m% LSS 10 set "duration_m=0%duration_m%"
  if %duration_s% LSS 10 set "duration_s=0%duration_s%"
  :: === Formatear centésimas a dos dígitos ===
  if %centis% LSS 10 set "centis=0%centis%"
  set "fmt_hhmmss=%duration_h%:%duration_m%:%duration_s%"
  set "fmt_hhmmsscc=%duration_h%:%duration_m%:%duration_s%,%centis%"

exit /b
