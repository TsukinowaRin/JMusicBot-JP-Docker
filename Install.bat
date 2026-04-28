@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

set "SCRIPT_DIR=%~dp0"
set "RELEASE_TAG=__RELEASE_TAG__"
if "%RELEASE_TAG:~0,2%"=="__" set "RELEASE_TAG="
set "RELEASE_REPO=TsukinowaRin/JMusicBot-JP-Docker"
if not "%JMUSICBOT_LAUNCHER_REPO%"=="" set "RELEASE_REPO=%JMUSICBOT_LAUNCHER_REPO%"
set "DOWNLOAD_URL=https://github.com/%RELEASE_REPO%/releases/download/%RELEASE_TAG%/JMusicBot-JP-Docker-%RELEASE_TAG%.zip"
set "TARGET_DIR=%SCRIPT_DIR%JMusicBot-JP-Docker-%RELEASE_TAG%"

where docker >nul 2>nul
if errorlevel 1 (
  echo Docker was not found. Install Docker Desktop or Docker Engine first.
  pause
  exit /b 1
)

if exist setup.bat (
  call setup.bat %*
  exit /b %ERRORLEVEL%
)

if "%RELEASE_TAG%"=="" (
  echo This installer does not have a release tag.
  echo Download Install-JMusicBot-Docker-Windows.bat from a GitHub release page, or use the zip bundle.
  pause
  exit /b 1
)

if exist "%TARGET_DIR%\setup.bat" (
  cd /d "%TARGET_DIR%"
  call setup.bat %*
  exit /b %ERRORLEVEL%
)

echo Local launcher files were not found.
echo Downloading JMusicBot-JP-Docker-%RELEASE_TAG%.zip ...
echo Extracting to: %TARGET_DIR%

set "POWERSHELL_EXE="
if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" set "POWERSHELL_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if "%POWERSHELL_EXE%"=="" if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" set "POWERSHELL_EXE=%ProgramFiles%\PowerShell\7\pwsh.exe"
if "%POWERSHELL_EXE%"=="" set "POWERSHELL_EXE=powershell"

"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$ProgressPreference = 'SilentlyContinue';" ^
  "$downloadUrl = $env:DOWNLOAD_URL;" ^
  "$scriptDir = [System.IO.Path]::GetFullPath($env:SCRIPT_DIR);" ^
  "$zipPath = Join-Path $env:TEMP ('JMusicBot-JP-Docker-' + $env:RELEASE_TAG + '.zip');" ^
  "Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath;" ^
  "Expand-Archive -Path $zipPath -DestinationPath $scriptDir -Force;"

if errorlevel 1 (
  echo Failed to download or extract the launcher bundle.
  pause
  exit /b 1
)

if not exist "%TARGET_DIR%\setup.bat" (
  echo Extracted bundle was not found: %TARGET_DIR%
  pause
  exit /b 1
)

cd /d "%TARGET_DIR%"
call setup.bat %*
exit /b %ERRORLEVEL%
