@echo off
setlocal
cd /d "%~dp0"

where docker >nul 2>nul
if errorlevel 1 (
  echo Docker が見つかりません。Docker Desktop もしくは Docker Engine をインストールしてください。
  pause
  exit /b 1
)

if not exist docker-data mkdir docker-data

echo Building and starting JMusicBot-JP launcher...
docker compose up -d --build
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
