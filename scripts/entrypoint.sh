#!/bin/sh
set -eu

APP_HOME="${APP_HOME:-/opt/jmusicbot-launcher}"
DATA_DIR="${JMUSICBOT_DATA_DIR:-/data}"
RUNTIME_DIR="${DATA_DIR}/runtime"
CONFIG_FILE="${DATA_DIR}/config.txt"
CONFIG_TEMPLATE="${APP_HOME}/config.template.txt"
RELEASE_REPO="${JMUSICBOT_RELEASE_REPO:-Cosgy-Dev/JMusicBot-JP}"
RELEASE_API_URL="${JMUSICBOT_RELEASE_API_URL:-https://api.github.com/repos/${RELEASE_REPO}/releases/latest}"
RELEASE_JSON="${RUNTIME_DIR}/latest-release.json"
JAR_PATH="${RUNTIME_DIR}/jmusicbot-latest-all.jar"
TAG_FILE="${RUNTIME_DIR}/release-tag.txt"

mkdir -p "${DATA_DIR}" "${DATA_DIR}/Playlists" "${DATA_DIR}/Mylists" "${DATA_DIR}/Publist" "${RUNTIME_DIR}"

fetch_latest_release() {
  curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "${RELEASE_API_URL}" \
    -o "${RELEASE_JSON}"
}

download_latest_jar() {
  latest_tag="$(jq -r '.tag_name' "${RELEASE_JSON}")"
  asset_url="$(jq -r '.assets[] | select(.name | test("-All\\.jar$")) | .browser_download_url' "${RELEASE_JSON}" | head -n 1)"
  asset_name="$(jq -r '.assets[] | select(.name | test("-All\\.jar$")) | .name' "${RELEASE_JSON}" | head -n 1)"

  if [ -z "${latest_tag}" ] || [ "${latest_tag}" = "null" ] || [ -z "${asset_url}" ]; then
    echo "Failed to resolve latest release asset from ${RELEASE_REPO}." >&2
    exit 1
  fi

  current_tag=""
  if [ -f "${TAG_FILE}" ]; then
    current_tag="$(cat "${TAG_FILE}")"
  fi

  if [ ! -f "${JAR_PATH}" ] || [ "${current_tag}" != "${latest_tag}" ]; then
    echo "Downloading ${asset_name} (${latest_tag})..."
    curl -fL --retry 3 --retry-delay 2 "${asset_url}" -o "${JAR_PATH}"
    printf '%s' "${latest_tag}" > "${TAG_FILE}"
  else
    echo "Latest jar already cached: ${latest_tag}"
  fi
}

ensure_config() {
  if [ ! -f "${CONFIG_FILE}" ]; then
    cp "${CONFIG_TEMPLATE}" "${CONFIG_FILE}"
    echo "Created ${CONFIG_FILE}. Edit token and owner, then rerun the launcher."
  fi

  if grep -Eq '^token[[:space:]]*=[[:space:]]*"(Botトークンをここに貼り付け|BOT_TOKEN_HERE)"' "${CONFIG_FILE}" \
    || grep -Eq '^owner[[:space:]]*=[[:space:]]*(所有者IDをここに貼り付け|0)([[:space:]]|$)' "${CONFIG_FILE}"; then
    cat <<EOF
${CONFIG_FILE} still has placeholder values.
Set valid values for:
  - token
  - owner
Then start the launcher again.
EOF
    exit 1
  fi
}

fetch_latest_release
download_latest_jar
ensure_config

cd "${DATA_DIR}"

exec java \
  ${JAVA_OPTS:-} \
  --enable-native-access=ALL-UNNAMED \
  -Dfile.encoding=UTF-8 \
  -Dnogui=true \
  -Dconfig.file="${CONFIG_FILE}" \
  -jar "${JAR_PATH}" \
  "$@"
