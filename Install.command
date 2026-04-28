#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RELEASE_TAG="__RELEASE_TAG__"
case "${RELEASE_TAG}" in
  __*) RELEASE_TAG="" ;;
esac
RELEASE_REPO="${JMUSICBOT_LAUNCHER_REPO:-TsukinowaRin/JMusicBot-JP-Docker}"
TARGET_DIR="${SCRIPT_DIR}/JMusicBot-JP-Docker-${RELEASE_TAG}"
DOWNLOAD_URL="https://github.com/${RELEASE_REPO}/releases/download/${RELEASE_TAG}/JMusicBot-JP-Docker-${RELEASE_TAG}.zip"

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
  if command -v ditto >/dev/null 2>&1; then
    ditto -x -k "$zip_path" "$destination"
  elif command -v unzip >/dev/null 2>&1; then
    unzip -o "$zip_path" -d "$destination"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$zip_path" "$destination" <<'PY'
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    archive.extractall(sys.argv[2])
PY
  else
    echo "ditto、unzip、python3 のいずれも見つかりません。zip bundle を手動で展開してください。" >&2
    return 1
  fi
}

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker が見つかりません。Docker Desktop または Docker Engine をインストールしてください。" >&2
  exit 1
fi

if [ -f "${SCRIPT_DIR}/setup.command" ]; then
  run_setup "${SCRIPT_DIR}/setup.command" "$@"
fi

if [ -z "${RELEASE_TAG}" ]; then
  echo "この installer には release tag が埋め込まれていません。" >&2
  echo "GitHub release page から Install-JMusicBot-Docker-macOS.command をダウンロードするか、zip bundle を使ってください。" >&2
  exit 1
fi

if [ -f "${TARGET_DIR}/setup.command" ]; then
  run_setup "${TARGET_DIR}/setup.command" "$@"
fi

echo "Local launcher files were not found."
echo "Downloading JMusicBot-JP-Docker-${RELEASE_TAG}.zip ..."
echo "Extracting to: ${TARGET_DIR}"

tmp_zip="${TMPDIR:-/tmp}/JMusicBot-JP-Docker-${RELEASE_TAG}.zip"
download_file "${DOWNLOAD_URL}" "${tmp_zip}"
extract_zip "${tmp_zip}" "${SCRIPT_DIR}"

if [ ! -f "${TARGET_DIR}/setup.command" ]; then
  echo "Extracted bundle was not found: ${TARGET_DIR}" >&2
  exit 1
fi

run_setup "${TARGET_DIR}/setup.command" "$@"
