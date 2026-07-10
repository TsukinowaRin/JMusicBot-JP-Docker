@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

set "ACTION=%~1"
set "CONFIG_FILE=docker-data\config.txt"
set "CONFIG_TEMPLATE=config.template.txt"

where docker >nul 2>nul
if errorlevel 1 (
  echo Docker が見つかりません。Docker Desktop もしくは Docker Engine をインストールしてください。
  pause
  exit /b 1
)

if not exist docker-data mkdir docker-data

if "%ACTION%"=="" (
  echo 操作を選択してください。
  echo 1^) セットアップ / 起動
  echo 2^) 更新
  echo 3^) 設定ファイルを開く
  echo 4^) ログを表示
  echo 5^) アンインストール
  choice /C 12345 /N /M "選択 [1/2/3/4/5]: "
  if errorlevel 5 (
    set "ACTION=uninstall"
  ) else if errorlevel 4 (
    set "ACTION=logs"
  ) else if errorlevel 3 (
    set "ACTION=config"
  ) else if errorlevel 2 (
    set "ACTION=update"
  ) else (
    set "ACTION=setup"
  )
  echo.
)

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
  echo Docker 起動に失敗しました。
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
  echo %CONFIG_TEMPLATE% が見つかりません。
  pause
  exit /b 1
)
copy "%CONFIG_TEMPLATE%" "%CONFIG_FILE%" >nul
if errorlevel 1 (
  echo %CONFIG_FILE% の作成に失敗しました。
  pause
  exit /b 1
)
echo %CONFIG_FILE% を作成しました。
exit /b 0

:config_has_placeholders
powershell -NoProfile -ExecutionPolicy Bypass -Command "$config = Get-Content -Raw -LiteralPath '%CONFIG_FILE%'; if ($config -match 'Botトークンをここに貼り付け|BOT_TOKEN_HERE|所有者IDをここに貼り付け' -or $config -match '(?m)^\s*owner\s*=\s*0\s*$') { exit 1 } exit 0"
exit /b %ERRORLEVEL%

:open_config
echo.
echo 設定ファイルを開きます: %CONFIG_FILE%
echo.
echo 最低限、次の 2 行を設定してください。
echo   token = "Discord Bot token"
echo   owner = 123456789012345678
echo.
echo token はダブルクォートあり、owner は数字のみです。
notepad "%CONFIG_FILE%"
exit /b 0

:ensure_configured
call :ensure_config_file
if errorlevel 1 exit /b %ERRORLEVEL%

call :config_has_placeholders
if not errorlevel 1 exit /b 0

echo.
echo %CONFIG_FILE% の token または owner が未設定です。
call :open_config

call :config_has_placeholders
if not errorlevel 1 exit /b 0

echo.
echo token または owner がまだ未設定です。
echo 設定後に setup.bat をもう一度実行してください。
pause
exit /b 1

:run_uninstall
echo JMusicBot-JP Docker container を停止して削除します。
echo docker-data は設定ファイルやプレイリストを含むため、既定では残します。
echo.

docker compose down --remove-orphans
docker rm -f jmusicbot-jp >nul 2>nul

echo.
choice /C YN /N /M "docker-data も削除しますか？ token / owner / playlists が消えます [y/N]: "
if errorlevel 2 (
  echo docker-data は残しました。
) else (
  if exist docker-data rmdir /S /Q docker-data
  echo docker-data を削除しました。
)

echo.
echo アンインストール処理が完了しました。
pause
exit /b 0
