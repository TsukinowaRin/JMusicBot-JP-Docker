#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "${SCRIPT_DIR}"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker が見つかりません。Docker Desktop または Docker Engine をインストールしてください。"
  exit 1
fi

mkdir -p docker-data

echo "Building and starting JMusicBot-JP launcher..."
docker compose up -d --build

if [ -f docker-data/config.txt ] && grep -q 'Botトークンをここに貼り付け' docker-data/config.txt; then
  echo
  echo "docker-data/config.txt が生成されました。token と owner を設定してください。"
  if command -v open >/dev/null 2>&1; then
    open docker-data/config.txt >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open docker-data/config.txt >/dev/null 2>&1 || true
  fi
fi

echo
docker compose logs --tail=50
