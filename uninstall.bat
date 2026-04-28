@echo off
setlocal
cd /d "%~dp0"
call setup.bat uninstall
exit /b %ERRORLEVEL%
