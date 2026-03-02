@echo off
:: =======================================================================================================================
:: PROGRAM:   startcontrol.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR:    [Telepieza - Mariano Vallespín]
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.0.0
:: DATE:      01/03/2026
:: LICENSE:   MIT License
:: DESCRIPTION: Security verification (Prevent direct execution). -Verificación de seguridad (Evitar ejecución directa)
:: =======================================================================================================================
setlocal
:: 1. Verificación de seguridad (Evitar ejecución directa)
:: Usamos "%~1" para limpiar comillas y asegurar que no venga vacío
if "%~1"=="" (
    cls
    :: Cambia la consola a UTF-8
    chcp 65001 >nul
    :: restaura el color default de Windows
    color
    echo.
    echo ===================================================================== 
    echo  [ERROR] Access denied. - Acceso denegado.
    echo  [INFO]  This script can only be invoked by tcd.bat.
    echo  [INFO]  Este script solo puede ser invocado por tcd.bat
    echo ===================================================================== 
    echo  Run from tcd.bat. Ejecutar desde el programa tcd.bat
    echo.
    pause
    cls
    :: Importante: exit /b termina el proceso actual sin cerrar la ventana, dando mensaje 1
    endlocal
    exit
)
:: 2. Salida normal
:: El exit /b 0 . La llamada es desde el tcd.bat
endlocal
exit /b 0
