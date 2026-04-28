#!/usr/bin/env bash
set -euo pipefail

WIN_CMD="${WIN_CMD:-cmd.exe}"
WIN_CODEX_CMD="${WIN_CODEX_CMD:-codex.cmd}"
WIN_CODEX_WORKDIR="${WIN_CODEX_WORKDIR:-$PWD}"

usage() {
  cat >&2 <<'USAGE'
Usage:
  win_codex.sh [--workdir <path>] [--] <codex-args...>

Examples:
  scripts/win_codex.sh --version
  scripts/win_codex.sh exec --skip-git-repo-check "hello"
  scripts/win_codex.sh --workdir <wsl-repo-path> exec "task"

Env:
  WIN_CMD           Windows-side command runner (default: cmd.exe)
  WIN_CODEX_CMD     Windows-side codex command (default: codex.cmd)
  WIN_CODEX_WORKDIR Working directory source path (default: current WSL cwd)
USAGE
  exit 2
}

to_wsl_path() {
  local input="$1"

  if [[ "$input" =~ ^[A-Za-z]:\\ ]]; then
    wslpath -u "$input"
    return 0
  fi

  printf '%s\n' "$input"
}

workdir="$WIN_CODEX_WORKDIR"
if [[ "${1-}" == "--workdir" ]]; then
  [[ $# -ge 3 ]] || usage
  workdir="$2"
  shift 2
fi

if [[ "${1-}" == "--" ]]; then
  shift
fi

if [[ $# -lt 1 ]]; then
  usage
fi

workdir="$(to_wsl_path "$workdir")"
if [[ ! -d "$workdir" ]]; then
  printf 'Working directory not found: %s\n' "$workdir" >&2
  exit 1
fi

(
  cd "$workdir"
  exec "$WIN_CMD" /d /c "$WIN_CODEX_CMD" "$@"
)
