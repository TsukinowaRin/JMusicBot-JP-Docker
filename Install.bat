@echo off
setlocal
cd /d "%~dp0"

set "SCRIPT_DIR=%~dp0"
set "RELEASE_TAG=__RELEASE_TAG__"
if "%RELEASE_TAG:~0,2%"=="__" set "RELEASE_TAG="
set "RELEASE_REPO=TsukinowaRin/JMusicBot-JP-Docker"
if not "%JMUSICBOT_LAUNCHER_REPO%"=="" set "RELEASE_REPO=%JMUSICBOT_LAUNCHER_REPO%"
set "DOWNLOAD_URL=https://github.com/%RELEASE_REPO%/releases/download/%RELEASE_TAG%/JMusicBot-JP-Docker-%RELEASE_TAG%.zip"
set "TARGET_DIR=%SCRIPT_DIR%JMusicBot-JP-Docker-%RELEASE_TAG%"

set "ACTION=%~1"

where docker >nul 2>nul
if errorlevel 1 (
  echo Docker was not found. Install Docker Desktop or Docker Engine first.
  pause
  exit /b 1
)

if not exist compose.yaml (
  call :bootstrap
  exit /b %ERRORLEVEL%
)

if not exist docker-data mkdir docker-data

if "%ACTION%"=="" (
  echo Select an action.
  echo 1^) Setup / Start
  echo 2^) Update
  choice /C 12 /N /M "Choice [1/2]: "
  if errorlevel 2 (
    set "ACTION=update"
  ) else (
    set "ACTION=setup"
  )
  echo.
)

if /I "%ACTION%"=="1" set "ACTION=setup"
if /I "%ACTION%"=="2" set "ACTION=update"

if /I "%ACTION%"=="setup" (
  echo Building and starting JMusicBot-JP launcher...
  docker compose up -d --build
) else if /I "%ACTION%"=="update" (
  echo Updating JMusicBot-JP launcher...
  docker compose down
  if exist docker-data\runtime rmdir /S /Q docker-data\runtime
  docker compose up -d --build --force-recreate
) else (
  echo Unknown action: %ACTION%
  echo Usage: Install.bat [setup^|update]
  pause
  exit /b 1
)

if errorlevel 1 (
  echo Docker startup failed.
  pause
  exit /b 1
)

if exist docker-data\config.txt (
  echo.
  echo Config file: docker-data\config.txt
  echo If this is your first start, edit token and owner, then run again.
)

echo.
docker compose logs --tail 50
pause
exit /b 0

:bootstrap
if "%RELEASE_TAG%"=="" (
  echo This installer does not have a release tag.
  echo Download Install.bat from a GitHub release page, or use the zip bundle.
  pause
  exit /b 1
)

if exist "%TARGET_DIR%\compose.yaml" (
  cd /d "%TARGET_DIR%"
  call Install.bat %ACTION%
  exit /b %ERRORLEVEL%
)

echo Local launcher files were not found.
echo Downloading JMusicBot-JP-Docker-%RELEASE_TAG%.zip ...

where powershell >nul 2>nul
if errorlevel 1 (
  echo Windows PowerShell was not found.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
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

if not exist "%TARGET_DIR%\compose.yaml" (
  echo Extracted bundle was not found: %TARGET_DIR%
  pause
  exit /b 1
)

cd /d "%TARGET_DIR%"
call Install.bat %ACTION%
exit /b %ERRORLEVEL%
