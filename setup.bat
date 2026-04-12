@echo off
setlocal
cd /d "%~dp0"

set "ACTION=%~1"

where docker >nul 2>nul
if errorlevel 1 (
  echo Docker was not found. Install Docker Desktop or Docker Engine first.
  pause
  exit /b 1
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
  echo Usage: setup.bat [setup^|update]
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
