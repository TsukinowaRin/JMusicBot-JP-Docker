@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

set "ACTION=%~1"
set "CONFIG_FILE=docker-data\config.txt"
set "CONFIG_TEMPLATE=config.template.txt"

where docker >nul 2>nul
if errorlevel 1 (
  echo Docker was not found. Install Docker Desktop or Docker Engine first.
  pause
  exit /b 1
)

if not exist docker-data mkdir docker-data

if not "%ACTION%"=="" goto normalize_action

echo Select an action.
echo [1] Setup / Start
echo [2] Update
echo [3] Open config.txt
echo [4] Show logs
echo [5] Uninstall
choice /C 12345 /N /M "Choice [1/2/3/4/5]: "
if errorlevel 5 set "ACTION=uninstall"
if errorlevel 4 if "%ACTION%"=="" set "ACTION=logs"
if errorlevel 3 if "%ACTION%"=="" set "ACTION=config"
if errorlevel 2 if "%ACTION%"=="" set "ACTION=update"
if "%ACTION%"=="" set "ACTION=setup"
echo.

:normalize_action

if /I "%ACTION%"=="1" set "ACTION=setup"
if /I "%ACTION%"=="2" set "ACTION=update"
if /I "%ACTION%"=="3" set "ACTION=config"
if /I "%ACTION%"=="4" set "ACTION=logs"
if /I "%ACTION%"=="5" set "ACTION=uninstall"
if /I "%ACTION%"=="start" set "ACTION=setup"
if /I "%ACTION%"=="edit" set "ACTION=config"
if /I "%ACTION%"=="remove" set "ACTION=uninstall"

if /I "%ACTION%"=="setup" (
  call :ensure_configured
  if errorlevel 1 exit /b %ERRORLEVEL%
  echo Building and starting JMusicBot-JP launcher...
  docker compose up -d --build
) else if /I "%ACTION%"=="update" (
  call :ensure_configured
  if errorlevel 1 exit /b %ERRORLEVEL%
  echo Updating JMusicBot-JP launcher...
  echo Keeping docker-data\config.txt and removing only docker-data\runtime.
  docker compose down
  if exist docker-data\runtime rmdir /S /Q docker-data\runtime
  docker compose up -d --build --force-recreate
) else if /I "%ACTION%"=="config" (
  call :ensure_config_file
  if errorlevel 1 exit /b %ERRORLEVEL%
  call :open_config
  exit /b %ERRORLEVEL%
) else if /I "%ACTION%"=="logs" (
  docker compose logs --tail 100
  pause
  exit /b %ERRORLEVEL%
) else if /I "%ACTION%"=="uninstall" (
  call :run_uninstall
  exit /b %ERRORLEVEL%
) else (
  echo Unknown action: %ACTION%
  echo Usage: setup.bat [setup^|update^|config^|logs^|uninstall]
  pause
  exit /b 1
)

if errorlevel 1 (
  echo Docker startup failed.
  pause
  exit /b 1
)

echo.
docker compose logs --tail 50
pause
exit /b 0

:ensure_config_file
if not exist docker-data mkdir docker-data
if exist "%CONFIG_FILE%" exit /b 0
if not exist "%CONFIG_TEMPLATE%" (
  echo %CONFIG_TEMPLATE% was not found.
  pause
  exit /b 1
)
copy "%CONFIG_TEMPLATE%" "%CONFIG_FILE%" >nul
if errorlevel 1 (
  echo Failed to create %CONFIG_FILE%.
  pause
  exit /b 1
)
echo Created %CONFIG_FILE%.
exit /b 0

:config_has_placeholders
powershell -NoProfile -ExecutionPolicy Bypass -Command "$config = Get-Content -Raw -LiteralPath '%CONFIG_FILE%'; $quote = [char]34; if ($config -match ('(?m)^\s*token\s*=\s*' + $quote + '(?:Bot|BOT_TOKEN_HERE)') -or $config -match '(?m)^\s*owner\s*=\s*(?:0|[^0-9\r\n])') { exit 1 } exit 0"
exit /b %ERRORLEVEL%

:open_config
echo.
echo Opening config file: %CONFIG_FILE%
echo.
echo Set at least these 2 lines.
echo   token = "Discord Bot token"
echo   owner = 123456789012345678
echo.
echo token must be quoted. owner must be numbers only.
notepad "%CONFIG_FILE%"
exit /b 0

:ensure_configured
call :ensure_config_file
if errorlevel 1 exit /b %ERRORLEVEL%

call :config_has_placeholders
if not errorlevel 1 exit /b 0

echo.
echo token or owner is not configured in %CONFIG_FILE%.
call :open_config

call :config_has_placeholders
if not errorlevel 1 exit /b 0

echo.
echo token or owner is still not configured.
echo Save the config, then run setup.bat again.
pause
exit /b 1

:run_uninstall
echo Stopping and removing the JMusicBot-JP Docker container.
echo docker-data contains config and playlists, so it is kept by default.
echo.

docker compose down --remove-orphans
docker rm -f jmusicbot-jp >nul 2>nul

echo.
choice /C YN /N /M "Delete docker-data too? token / owner / playlists will be removed [y/N]: "
if errorlevel 2 (
  echo Kept docker-data.
) else (
  if exist docker-data rmdir /S /Q docker-data
  echo Deleted docker-data.
)

echo.
echo Uninstall completed.
pause
exit /b 0
