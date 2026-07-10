#!/bin/sh
set -eu

APP_HOME="${APP_HOME:-/opt/jmusicbot}"
DATA_DIR="${JMUSICBOT_DATA_DIR:-/data}"
CONFIG_FILE="${JMUSICBOT_CONFIG_FILE:-${DATA_DIR}/config.txt}"
REFERENCE_CONF="${APP_HOME}/reference.conf"

mkdir -p "${DATA_DIR}" "${DATA_DIR}/Playlists" "${DATA_DIR}/Mylists" "${DATA_DIR}/Publist"

create_default_config() {
  awk '
    /^\/\/\/ START OF JMUSICBOT-JP CONFIG \/\// { in_block=1; next }
    /^\/\/\/ END OF JMUSICBOT-JP CONFIG \/\// { in_block=0; exit }
    in_block { print }
  ' "${REFERENCE_CONF}" > "${CONFIG_FILE}"
}

if [ ! -f "${CONFIG_FILE}" ]; then
  create_default_config
  echo "Created ${CONFIG_FILE} from the bundled template."
fi

if grep -Eq '^token[[:space:]]*=[[:space:]]*"(Botトークンをここに貼り付け|BOT_TOKEN_HERE)"' "${CONFIG_FILE}" \
  || grep -Eq '^owner[[:space:]]*=[[:space:]]*(所有者IDをここに貼り付け|0)([[:space:]]|$)' "${CONFIG_FILE}"; then
  cat <<EOF
${CONFIG_FILE} still contains placeholder values.
Set valid values for:
  - token
  - owner

After editing the file, start the container again.
EOF
  exit 1
fi

cd "${DATA_DIR}"

exec java \
  ${JAVA_OPTS:-} \
  --enable-native-access=ALL-UNNAMED \
  -Dfile.encoding=UTF-8 \
  -Dnogui=true \
  -Dconfig.file="${CONFIG_FILE}" \
  -jar "${APP_HOME}/jmusicbot.jar" \
  "$@"
