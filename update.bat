@echo off
setlocal
cd /d "%~dp0"
call setup.bat update
exit /b %ERRORLEVEL%
