#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RELEASE_TAG="__RELEASE_TAG__"
case "${RELEASE_TAG}" in
  __*) RELEASE_TAG="" ;;
esac
RELEASE_REPO="${JMUSICBOT_LAUNCHER_REPO:-TsukinowaRin/JMusicBot-JP-Docker}"
DOWNLOAD_URL="https://github.com/${RELEASE_REPO}/releases/download/${RELEASE_TAG}/JMusicBot-JP-Docker-${RELEASE_TAG}.zip"

if [ -n "${JMUSICBOT_INSTALL_DIR:-}" ]; then
  INSTALL_DIR="${JMUSICBOT_INSTALL_DIR}"
elif [ -n "${XDG_DATA_HOME:-}" ]; then
  INSTALL_DIR="${XDG_DATA_HOME}/jmusicbot-jp-docker"
else
  INSTALL_DIR="${HOME}/.local/share/jmusicbot-jp-docker"
fi

run_setup() {
  setup_path="$1"
  shift
  if [ -x "${setup_path}" ]; then
    exec "${setup_path}" "$@"
  fi
  exec sh "${setup_path}" "$@"
}

download_file() {
  url="$1"
  output="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fL "$url" -o "$output"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$output" "$url"
  else
    echo "curl または wget が見つかりません。zip bundle を手動でダウンロードしてください。" >&2
    return 1
  fi
}

extract_zip() {
  zip_path="$1"
  destination="$2"
  if command -v unzip >/dev/null 2>&1; then
    unzip -o "$zip_path" -d "$destination"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$zip_path" "$destination" <<'PY'
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    archive.extractall(sys.argv[2])
PY
  elif command -v ditto >/dev/null 2>&1; then
    ditto -x -k "$zip_path" "$destination"
  else
    echo "unzip、python3、ditto のいずれも見つかりません。zip bundle を手動で展開してください。" >&2
    return 1
  fi
}

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker が見つかりません。Docker Desktop または Docker Engine をインストールしてください。" >&2
  exit 1
fi

if [ -f "${SCRIPT_DIR}/setup.sh" ]; then
  run_setup "${SCRIPT_DIR}/setup.sh" "$@"
fi

if [ -z "${RELEASE_TAG}" ]; then
  echo "この installer には release tag が埋め込まれていません。" >&2
  echo "GitHub release page から Install-JMusicBot-Docker-Linux.sh をダウンロードするか、zip bundle を使ってください。" >&2
  exit 1
fi

echo "Installing JMusicBot-JP Docker launcher to:"
echo "  ${INSTALL_DIR}"
echo

tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/jmusicbot-jp-docker.XXXXXX")
trap 'rm -rf "${tmp_root}"' EXIT HUP INT TERM
tmp_zip="${tmp_root}/JMusicBot-JP-Docker-${RELEASE_TAG}.zip"
source_dir="${tmp_root}/JMusicBot-JP-Docker-${RELEASE_TAG}"

download_file "${DOWNLOAD_URL}" "${tmp_zip}"
extract_zip "${tmp_zip}" "${tmp_root}"

if [ ! -f "${source_dir}/setup.sh" ]; then
  echo "Extracted bundle was not found: ${source_dir}" >&2
  exit 1
fi

mkdir -p "${INSTALL_DIR}"
cp -R "${source_dir}/." "${INSTALL_DIR}/"
chmod +x "${INSTALL_DIR}/setup.sh" "${INSTALL_DIR}/setup.command" "${INSTALL_DIR}/update.sh" "${INSTALL_DIR}/uninstall.sh" "${INSTALL_DIR}/Install.sh" "${INSTALL_DIR}/Install.command" "${INSTALL_DIR}/scripts/entrypoint.sh" 2>/dev/null || true

run_setup "${INSTALL_DIR}/setup.sh" "$@"
