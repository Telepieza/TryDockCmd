@echo off
:: ==============================================================================
:: PROGRAM:   message.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.1.0
:: DATE:      28/04/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Message version 7 y 8
:: ==============================================================================
setlocal enabledelayedexpansion
:: Cambia la consola a UTF-8
chcp 65001 >nul
:: Analiza si la llamada es del tcd.bat
set "tipo="
set "msg="
set /a "numer=0"
set "space="
:: %~1=Nivel de error (INFO,ERROR,DEBUG,TXT,WORK,APP,SUCC), %~2=El mensaje traducido
if /i "%~1" NEQ "" set "tipo=%~1"
if /i "%~2" NEQ "" set "msg=%~2"
if /i "%~3" NEQ "" set /a "numer=%~3"
:: Leemos secuencia de colores
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
:: Definir colores estándar (No brillantes)
set "C_GREY=%ESC%[30m"     :: Gris                   
set "C_RED=%ESC%[31m"      :: Rojo       
set "C_GREEN=%ESC%[32m"    :: Verde      
set "C_YELLOW=%ESC%[33m"   :: Amarillo  
set "C_BLUE=%ESC%[34m"     :: Azul       
set "C_MAG=%ESC%[35m"      :: Magenta    
set "C_CYAN=%ESC%[36m"     :: Cian       
set "C_WHITE=%ESC%[37m"    :: Blanco    Texto Base

set "C_RESET=%ESC%[0m"     :: Reset     (Vuelve al color original)

set "C_B_GREY=%ESC%[90m"	 :: Gris Brillante   (Crítico)
set "C_B_RED=%ESC%[91m"	   :: Rojo Brillante   (Crítico)
set "C_B_GREEN=%ESC%[92m"	 :: Verde Lima       (Éxito total)
set "C_B_YELLOW=%ESC%[93m" ::	Amarillo Intenso (Atención)
set "C_B_BLUE=%ESC%[94m"	 :: Azul Eléctrico   (Enlaces/Primario)
set "C_B_MAG=%ESC%[95m"	   :: Magenta Brillante
set "C_B_CYAN=%ESC%[96m"	 :: Cian Brillante   (Instrucciones)
set "C_B_WHITE=%ESC%[97m"	 :: Blanco Puro      (Resaltado)

set "color_local=!C_RESET!"
:: Asignar color según el tipo (solo para pantalla)
if /i "!tipo!"=="!LOG-ERROR!"  set "color_local=!C_B_RED!"
if /i "!tipo!"=="!LOG-ALERT!"  set "color_local=!C_B_RED!"
if /i "!tipo!"=="!LOG-INFO!"   set "color_local=!C_B_CYAN!"
if /i "!tipo!"=="!LOG-CANCEL!" set "color_local=!C_B_MAG!"
if /i "!tipo!"=="!LOG-WARN!"   set "color_local=!C_B_YELLOW!"
if /i "!tipo!"=="!LOG-DEBUG!"  set "color_local=!C_B_CYAN!"
if /i "!tipo!"=="!LOG-SUCC!"   set "color_local=!C_B_GREEN!"
if /i "!tipo!"=="%ERR%"        set "color_local=!C_B_RED!"
if /i "!tipo!"=="%INS%"        set "color_local=!C_B_YELLOW!"
if /i "!tipo!"=="%CHECK%"      set "color_local=!C_B_WHITE!"
:: Visualizar mensaje en pantalla con colores, procesa los echo si hay valor en la variable msg
:: Si tipo=APP no visualiza en consola, tipo=TXT pone tipo a blanco y no realiza el echo con el tipo para no visualizar un blanco del mensaje en consola
if /i "!msg!" equ "" goto :exit
if /i "!tipo!"=="%CHECK%" (
    (echo [%DATE% %TIME%] !tipo! !msg!)>>"%LOGGER%"
    goto :exit
)
if /i "!tipo!"=="%APP%" (
    (echo [%DATE% %TIME%] !tipo! !msg!)>>"%LOGGER%"
    goto :exit
)
set "sin_tipo=0"
if /i "!tipo!"=="%TXT%" set "sin_tipo=1"
if /i "!tipo!"=="%SQL%" set "sin_tipo=1"
if /i "!tipo!"=="%MENU%" set "sin_tipo=1"
if /i "!tipo!"=="%INS%" set "sin_tipo=1"
if /i "!tipo!"=="" set "sin_tipo=1"
   
if "!sin_tipo!"=="1" ( 
    if %numer% GTR 0 (
      for /l %%i in (1,1,%numer%) do (
       set "space=!space! "
      )
    )
    echo !color_local!!space!!msg!!C_RESET!
)

if "!sin_tipo!"=="0" echo !color_local!!tipo! !msg!!C_RESET!
if /i "!tipo!"=="" set tipo=%TXT%
if /i "!tipo!" NEQ "%MENU%" (echo [%DATE% %TIME%] !tipo! !msg!)>>"%LOGGER%"

:exit
  endlocal
  exit /b
