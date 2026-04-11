#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "${SCRIPT_DIR}"

ACTION="${1:-}"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker が見つかりません。Docker Desktop または Docker Engine をインストールしてください。"
  exit 1
fi

mkdir -p docker-data

choose_action() {
  if [ -n "${ACTION}" ]; then
    return
  fi

  if [ ! -t 0 ]; then
    ACTION="setup"
    return
  fi

  echo "操作を選択してください。"
  echo "1) セットアップ / 起動"
  echo "2) 更新"
  printf "選択 [1/2]: "
  read -r selection || true
  case "${selection:-1}" in
    2)
      ACTION="update"
      ;;
    *)
      ACTION="setup"
      ;;
  esac
}

run_setup() {
  echo "Building and starting JMusicBot-JP launcher..."
  docker compose up -d --build
}

run_update() {
  echo "Updating JMusicBot-JP launcher..."
  docker compose down
  rm -rf docker-data/runtime
  docker compose up -d --build --force-recreate
}

open_config_if_needed() {
  if [ -f docker-data/config.txt ] && grep -q 'Botトークンをここに貼り付け' docker-data/config.txt; then
    echo
    echo "docker-data/config.txt が生成されました。token と owner を設定してください。"
    if command -v open >/dev/null 2>&1; then
      open docker-data/config.txt >/dev/null 2>&1 || true
    elif command -v xdg-open >/dev/null 2>&1; then
      xdg-open docker-data/config.txt >/dev/null 2>&1 || true
    fi
  fi
}

choose_action

case "${ACTION}" in
  1|setup|start)
    run_setup
    ;;
  2|update)
    run_update
    ;;
  *)
    echo "Unknown action: ${ACTION}" >&2
    echo "Usage: ./setup.sh [setup|update]" >&2
    exit 1
    ;;
esac

open_config_if_needed

echo
docker compose logs --tail=50
