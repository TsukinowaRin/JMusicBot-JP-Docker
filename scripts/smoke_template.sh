#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
PYCACHE_DIR="$(mktemp -d /tmp/template-pycache.XXXXXX)"
trap 'rm -rf "$PYCACHE_DIR"' EXIT

log() {
  printf '[smoke] %s\n' "$1"
}

run() {
  log "$*"
  "$@"
}

run bash -n scripts/win_pwsh.sh
run bash -n scripts/win_codex.sh
run env PYTHONPYCACHEPREFIX="$PYCACHE_DIR" python3 -m py_compile \
  .agent-shared/hooks_core/common.py \
  .agent-shared/hooks_core/runtime.py \
  .agents/skills/local-skill-bootstrap/scripts/init_skill.py \
  .codex/hooks/session_start_context.py \
  .codex/hooks/pre_tool_use_policy.py \
  .claude/hooks/session_start_context.py \
  .claude/hooks/pre_tool_use_policy.py \
  .gemini/hooks/session_start_context.py \
  .gemini/hooks/before_tool_policy.py \
  scripts/sync_shared_skills_to_claude.py
run python3 scripts/sync_shared_skills_to_claude.py

for required in \
  README.md \
  AGENTS.md \
  CLAUDE.md \
  GEMINI.md \
  docs/INDEX.md \
  docs/AGENT_BOOTSTRAP.md \
  docs/BEST_PRACTICES_SOURCES.md \
  docs/TOOL_PLAYBOOK.md \
  docs/PROJECT_BRIEF.md \
  docs/REQS.md \
  docs/WORKLOG.md \
  scripts/win_pwsh.sh \
  scripts/win_codex.sh \
  scripts/wsl_exec.ps1 \
  scripts/wsl_exec.cmd
do
  if [[ ! -e "$required" ]]; then
    printf '[smoke] missing required file: %s\n' "$required" >&2
    exit 1
  fi
done

run scripts/win_pwsh.sh '$PSVersionTable.PSVersion.ToString()'
run scripts/win_codex.sh --version
run cmd.exe /d /c scripts\\wsl_exec.cmd -Workdir "$ROOT" -Exec pwd
