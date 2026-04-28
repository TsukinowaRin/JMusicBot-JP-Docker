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
if not "%JMUSICBOT_INSTALL_DIR%"=="" (
  set "INSTALL_DIR=%JMUSICBOT_INSTALL_DIR%"
) else if not "%LOCALAPPDATA%"=="" (
  set "INSTALL_DIR=%LOCALAPPDATA%\JMusicBot-JP-Docker"
) else (
  set "INSTALL_DIR=%USERPROFILE%\AppData\Local\JMusicBot-JP-Docker"
)

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

echo Installing JMusicBot-JP Docker launcher to:
echo   %INSTALL_DIR%
echo.

set "POWERSHELL_EXE="
if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" set "POWERSHELL_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if "%POWERSHELL_EXE%"=="" if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" set "POWERSHELL_EXE=%ProgramFiles%\PowerShell\7\pwsh.exe"
if "%POWERSHELL_EXE%"=="" set "POWERSHELL_EXE=powershell"

"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$ProgressPreference = 'SilentlyContinue';" ^
  "$downloadUrl = $env:DOWNLOAD_URL;" ^
  "$installDir = [System.IO.Path]::GetFullPath($env:INSTALL_DIR);" ^
  "$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('JMusicBot-JP-Docker-' + $env:RELEASE_TAG + '-' + [guid]::NewGuid().ToString('N'));" ^
  "$zipPath = Join-Path $tempRoot ('JMusicBot-JP-Docker-' + $env:RELEASE_TAG + '.zip');" ^
  "$sourceDir = Join-Path $tempRoot ('JMusicBot-JP-Docker-' + $env:RELEASE_TAG);" ^
  "New-Item -ItemType Directory -Force -Path $tempRoot, $installDir | Out-Null;" ^
  "try {" ^
  "  Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath;" ^
  "  Expand-Archive -Path $zipPath -DestinationPath $tempRoot -Force;" ^
  "  if (-not (Test-Path -LiteralPath (Join-Path $sourceDir 'setup.bat'))) { throw ('Extracted bundle was not found: ' + $sourceDir) }" ^
  "  Copy-Item -Path (Join-Path $sourceDir '*') -Destination $installDir -Recurse -Force;" ^
  "} finally {" ^
  "  Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue;" ^
  "}"

if errorlevel 1 (
  echo Failed to download or install the launcher bundle.
  pause
  exit /b 1
)

if not exist "%INSTALL_DIR%\setup.bat" (
  echo Installed setup.bat was not found: %INSTALL_DIR%
  pause
  exit /b 1
)

cd /d "%INSTALL_DIR%"
call setup.bat %*
exit /b %ERRORLEVEL%
