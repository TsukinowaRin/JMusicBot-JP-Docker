@echo off
setlocal
cd /d "%~dp0"

set "ACTION=%~1"

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
  choice /C 12 /N /M "選択 [1/2]: "
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
  echo Docker 起動に失敗しました。
  pause
  exit /b 1
)

if exist docker-data\config.txt (
  findstr /C:"Botトークンをここに貼り付け" docker-data\config.txt >nul
  if not errorlevel 1 (
    echo.
    echo docker-data\config.txt が生成されました。token と owner を設定してください。
    start "" notepad docker-data\config.txt
  )
)

echo.
docker compose logs --tail 50
pause
