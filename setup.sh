#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "${SCRIPT_DIR}"

ACTION="${1:-}"
CONFIG_FILE="docker-data/config.txt"
CONFIG_TEMPLATE="config.template.txt"

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
  echo "3) 設定ファイルを開く"
  echo "4) ログを表示"
  echo "5) アンインストール"
  printf "選択 [1/2/3/4/5]: "
  read -r selection || true
  case "${selection:-1}" in
    2)
      ACTION="update"
      ;;
    3)
      ACTION="config"
      ;;
    4)
      ACTION="logs"
      ;;
    5)
      ACTION="uninstall"
      ;;
    *)
      ACTION="setup"
      ;;
  esac
}

ensure_config_file() {
  mkdir -p docker-data
  if [ -f "${CONFIG_FILE}" ]; then
    return 0
  fi
  if [ ! -f "${CONFIG_TEMPLATE}" ]; then
    echo "${CONFIG_TEMPLATE} が見つかりません。" >&2
    return 1
  fi
  cp "${CONFIG_TEMPLATE}" "${CONFIG_FILE}"
  echo "${CONFIG_FILE} を作成しました。"
}

config_has_placeholders() {
  grep -Eq '^token[[:space:]]*=[[:space:]]*"(Botトークンをここに貼り付け|BOT_TOKEN_HERE)"' "${CONFIG_FILE}" \
    || grep -Eq '^owner[[:space:]]*=[[:space:]]*(所有者IDをここに貼り付け|0)([[:space:]]|$)' "${CONFIG_FILE}"
}

open_config() {
  echo
  echo "設定ファイルを開きます: ${CONFIG_FILE}"
  echo
  echo "最低限、次の 2 行を設定してください。"
  echo '  token = "Discord Bot token"'
  echo "  owner = 123456789012345678"
  echo
  echo "token はダブルクォートあり、owner は数字のみです。"

  editor="${VISUAL:-${EDITOR:-}}"
  if [ -n "${editor}" ]; then
    ${editor} "${CONFIG_FILE}"
  elif command -v open >/dev/null 2>&1; then
    open "${CONFIG_FILE}" >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "${CONFIG_FILE}" >/dev/null 2>&1 || true
  else
    echo "エディタを自動起動できませんでした。${CONFIG_FILE} を手動で編集してください。"
  fi
}

ensure_configured() {
  ensure_config_file
  if ! config_has_placeholders; then
    return 0
  fi

  echo
  echo "${CONFIG_FILE} の token または owner が未設定です。"
  if [ -t 0 ]; then
    open_config
  else
    echo "${CONFIG_FILE} を編集してから、もう一度実行してください。"
    return 1
  fi

  if ! config_has_placeholders; then
    return 0
  fi

  echo
  echo "token または owner がまだ未設定です。"
  echo "設定後に ./setup.sh をもう一度実行してください。"
  return 1
}

run_setup() {
  ensure_configured
  echo "Building and starting JMusicBot-JP launcher..."
  docker compose up -d --build
}

run_update() {
  ensure_configured
  echo "Updating JMusicBot-JP launcher..."
  echo "${CONFIG_FILE} は残し、docker-data/runtime の jar cache だけを削除します。"
  docker compose down
  rm -rf docker-data/runtime
  docker compose up -d --build --force-recreate
}

run_uninstall() {
  echo "JMusicBot-JP Docker container を停止して削除します。"
  echo "docker-data は設定ファイルやプレイリストを含むため、既定では残します。"
  echo

  docker compose down --remove-orphans || true
  docker rm -f jmusicbot-jp >/dev/null 2>&1 || true

  if [ -t 0 ]; then
    printf "docker-data も削除しますか？ token / owner / playlists が消えます [y/N]: "
    read -r delete_data || true
    case "${delete_data:-N}" in
      y|Y|yes|YES)
        rm -rf docker-data
        echo "docker-data を削除しました。"
        ;;
      *)
        echo "docker-data は残しました。"
        ;;
    esac
  else
    echo "非対話実行のため docker-data は残しました。"
  fi

  echo
  echo "アンインストール処理が完了しました。"
}

choose_action

case "${ACTION}" in
  1|setup|start)
    run_setup
    ;;
  2|update)
    run_update
    ;;
  3|config|edit)
    ensure_config_file
    open_config
    exit 0
    ;;
  4|logs)
    docker compose logs --tail=100
    exit 0
    ;;
  5|uninstall|remove)
    run_uninstall
    exit 0
    ;;
  *)
    echo "Unknown action: ${ACTION}" >&2
    echo "Usage: ./setup.sh [setup|update|config|logs|uninstall]" >&2
    exit 1
    ;;
esac

echo
docker compose logs --tail=50
