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

echo [1/5] Checking Docker command...
where docker >nul 2>nul
if errorlevel 1 (
  echo Docker was not found. Install Docker Desktop or Docker Engine first.
  pause
  exit /b 1
)
echo       OK: Docker command found.
echo.

if exist setup.bat (
  echo Local launcher files were found next to this installer.
  echo Starting local setup.bat...
  echo.
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
  "Write-Host '[2/5] Preparing install directory and temporary workspace...';" ^
  "Write-Host ('      Install: ' + $installDir);" ^
  "Write-Host ('      Temp:    ' + $tempRoot);" ^
  "New-Item -ItemType Directory -Force -Path $tempRoot, $installDir | Out-Null;" ^
  "try {" ^
  "  Write-Host '[3/5] Downloading release bundle...';" ^
  "  Write-Host ('      URL: ' + $downloadUrl);" ^
  "  Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath;" ^
  "  Write-Host ('      Saved: ' + $zipPath);" ^
  "  Write-Host '[4/5] Extracting and copying launcher files...';" ^
  "  Expand-Archive -Path $zipPath -DestinationPath $tempRoot -Force;" ^
  "  if (-not (Test-Path -LiteralPath (Join-Path $sourceDir 'setup.bat'))) { throw ('Extracted bundle was not found: ' + $sourceDir) }" ^
  "  Copy-Item -Path (Join-Path $sourceDir '*') -Destination $installDir -Recurse -Force;" ^
  "  Write-Host '      Launcher files copied.';" ^
  "} finally {" ^
  "  Write-Host '      Cleaning temporary files...';" ^
  "  Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue;" ^
  "}"

if errorlevel 1 (
  echo Failed to download or install the launcher bundle.
  pause
  exit /b 1
)

echo.
echo [5/5] Verifying installed launcher files...
if not exist "%INSTALL_DIR%\setup.bat" (
  echo Installed setup.bat was not found: %INSTALL_DIR%
  pause
  exit /b 1
)
if not exist "%INSTALL_DIR%\compose.yaml" (
  echo Installed compose.yaml was not found: %INSTALL_DIR%
  pause
  exit /b 1
)
if not exist "%INSTALL_DIR%\config.template.txt" (
  echo Installed config.template.txt was not found: %INSTALL_DIR%
  pause
  exit /b 1
)
echo       OK: setup.bat, compose.yaml, and config.template.txt were installed.
echo.
echo Starting setup.bat from:
echo   %INSTALL_DIR%
echo.

cd /d "%INSTALL_DIR%"
call setup.bat %*
exit /b %ERRORLEVEL%
