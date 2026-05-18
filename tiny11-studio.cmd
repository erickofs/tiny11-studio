@echo off
title tiny11 Studio
:: ============================================================
:: tiny11-studio.cmd - Launcher with automatic UAC elevation
:: Double-click this file to run tiny11 Studio as Administrator
:: ============================================================

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -Verb RunAs -FilePath '%~f0'"
    exit /b
)

:: We are admin - launch the script
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tiny11-studio.ps1"

:: Keep window open on error
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] tiny11 Studio exited with code %errorlevel%
    pause
)
