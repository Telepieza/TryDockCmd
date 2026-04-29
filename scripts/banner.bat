@echo off
:: ===============================================================================
:: PROGRAM:   banner.bat
:: PROJECT:   Tryton Docker Manager
:: AUTHOR: Telepieza
:: COLLABORATOR: Gemini (Google AI)
:: VERSION:   1.1.25
:: DATE:      29/04/2026
:: LICENSE:   MIT License
:: DESCRIPTION: banner
:: ==============================================================================
setlocal
chcp 65001 >nul
call "%DIR_SCRIPT%startcontrol.bat" "%~1"
set "B_ESC= "
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "B_ESC=%%b"
set "B_GREY=%B_ESC%[90m"
set "B_B_CYAN=%B_ESC%[96m"
set "B_CYAN=%B_ESC%[36m"
set "B_WHITE=%B_ESC%[97m"
set "B_RESET=%B_ESC%[0m"
echo.
echo %B_GREY%       ###################################################################
echo        #                                                                 #
echo        #  %B_CYAN%_______ _______     _______  ____   ______ _  __ _____ __  __ %B_GREY% #
echo        # %B_CYAN%^|__   __^|  __ \ \   / /  __ \/ __ \ / _____^| ^|/ // ____^|  \/  ^|%B_GREY% #
echo        # %B_CYAN%   ^| ^|  ^| ^|__) \ \_/ /^| ^|  ^| ^| ^|  ^| ^| ^|    ^| ' /^| ^|    ^| \  / ^|%B_GREY% #
echo        # %B_CYAN%   ^| ^|  ^|  _  / \   / ^| ^|  ^| ^| ^|  ^| ^| ^|    ^|  ^< ^| ^|    ^| ^|\/^| ^|%B_GREY% #
echo        # %B_CYAN%   ^| ^|  ^| ^| \ \  ^| ^|  ^| ^|__^| ^| ^|__^| ^| ^|____^| . \^| ^|____^| ^|  ^| ^|%B_GREY% #
echo        # %B_CYAN%   ^|_^|  ^|_^|  \_\ ^|_^|  ^|_____/\____/ \______^|_^|\_\\_____^|_^|  ^|_^|%B_GREY% #
echo        #                                                                 #
echo        #                  %B_WHITE%TRYDOCKCMD DOCKER MANAGER v1.1.25%B_GREY%              #
echo        #          ------------------------------------------             #
echo        #          Maintenance - Security - ERP Optimization              #
echo        # Tryton (V7/V8) ERP Docker Manager     https://www.telepieza.com #
echo        ###################################################################%B_RESET%
echo.

:exit
  endlocal
  exit /b 0