#!/usr/bin/env bash
set -euo pipefail

# ハーネス v2 の構造 smoke。prompt では守れない構造制約（必須ファイル、廃止物の
# 復活、stale 参照、skill metadata、mirror 一致、hooks 構文、policy 動作）を
# deterministic に検証する。設計の正本は docs/HARNESS.md。

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

run_optional_windows() {
  local status

  if [[ "${TEMPLATE_SMOKE_WINDOWS:-auto}" == "0" ]]; then
    log "skip optional Windows smoke: $*"
    return 0
  fi

  log "optional Windows smoke: $*"
  set +e
  timeout "${TEMPLATE_SMOKE_WINDOWS_TIMEOUT:-30s}" "$@"
  status=$?
  set -e
  if [[ "$status" -eq 0 ]]; then
    return 0
  fi

  if [[ "${TEMPLATE_SMOKE_WINDOWS:-auto}" == "1" ]]; then
    log "required Windows smoke failed with exit code ${status}: $*"
    return "$status"
  fi

  log "optional Windows smoke skipped/failed with exit code ${status}: $*"
  return 0
}

check_codex_config() {
  python3 - "$1" <<'PY'
import pathlib
import sys
import tomllib

path = pathlib.Path(sys.argv[1])
data = tomllib.loads(path.read_text())
if data.get("features", {}).get("hooks") is not True:
    raise SystemExit(f"{path}: [features].hooks must be true")
if "codex_hooks" in data.get("features", {}):
    raise SystemExit(f"{path}: [features].codex_hooks is deprecated")
fallbacks = data.get("project_doc_fallback_filenames", [])
if "GEMINI.md" in fallbacks:
    raise SystemExit(f"{path}: GEMINI.md must not be a Codex fallback doc")
hooks = data.get("hooks", {})
if "SessionStart" not in hooks or "PreToolUse" not in hooks:
    raise SystemExit(f"{path}: missing required Codex hooks")
PY
}

check_admin_policy() {
  python3 - <<'PY'
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(".agent-shared").resolve()))
from hooks_core import evaluate_tool_use


def violation(command):
    return evaluate_tool_use("Bash", {"command": command})


if "管理者権限" not in (violation("sudo apt update") or ""):
    raise SystemExit("sudo without approval marker must be blocked")
if "管理者権限" not in (violation("scripts/win_pwsh.sh 'Start-Process powershell -Verb RunAs'") or ""):
    raise SystemExit("Windows RunAs without approval marker must be blocked")
if violation("AGENT_ADMIN_APPROVED=1 sudo apt update") is not None:
    raise SystemExit("approved sudo command should pass admin escalation policy")
if "破壊的" not in (violation("AGENT_ADMIN_APPROVED=1 sudo rm -rf /") or ""):
    raise SystemExit("approval marker must not bypass destructive command policy")

print("Admin escalation policy OK")
PY
}

check_cursor_policy() {
  # Cursor adapter は tool_name なしの payload を受けるため、shell / read の
  # 両経路が hooks_core の policy に正しく写像されることを確認する。
  python3 - <<'PY'
import json
import pathlib
import subprocess
import sys


def run_hook(payload):
    proc = subprocess.run(
        [sys.executable, ".cursor/hooks/pre_tool_use_policy.py"],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(proc.stdout) if proc.stdout.strip() else None


denied = run_hook({"command": "git reset --hard HEAD~1"})
if not denied or denied.get("permission") != "deny":
    raise SystemExit("cursor hook must deny destructive shell commands")
denied = run_hook({"file_path": "/repo/.env"})
if not denied or denied.get("permission") != "deny":
    raise SystemExit("cursor hook must deny secret file reads")
if run_hook({"command": "git status"}) is not None:
    raise SystemExit("cursor hook must allow safe shell commands")
if run_hook({"file_path": "README.md"}) is not None:
    raise SystemExit("cursor hook must allow normal file reads")

print("Cursor policy OK")
PY
}

check_skill_metadata() {
  python3 - "$@" <<'PY'
import pathlib
import re
import sys

# 複数 CLI が skill directory を直接検出する。opencode は name/description と
# directory 名の一致を要求するため、ここで落として「skill が黙って隠れる」
# release を防ぐ。
name_re = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")


def read_frontmatter(path):
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "---":
        raise SystemExit(f"{path}: missing YAML frontmatter")

    data = {}
    for line in lines[1:]:
        if line.strip() == "---":
            return data
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if ":" not in line:
            raise SystemExit(f"{path}: invalid frontmatter line: {line!r}")
        key, value = line.split(":", 1)
        data[key.strip()] = value.strip().strip("'\"")

    raise SystemExit(f"{path}: unterminated YAML frontmatter")


for root in sys.argv[1:]:
    base = pathlib.Path(root)
    if not base.exists():
        raise SystemExit(f"{base}: missing skill root")
    for path in sorted(base.glob("*/SKILL.md")):
        data = read_frontmatter(path)
        expected = path.parent.name
        name = data.get("name", "")
        description = data.get("description", "")
        if name != expected:
            raise SystemExit(f"{path}: name must match directory ({expected})")
        if not (1 <= len(name) <= 64) or not name_re.fullmatch(name):
            raise SystemExit(f"{path}: invalid skill name {name!r}")
        if not (1 <= len(description) <= 1024):
            raise SystemExit(f"{path}: description must be 1..1024 chars")

print("Skill metadata OK")
PY
}

check_skill_mirrors() {
  python3 - "$@" <<'PY'
import filecmp
import pathlib
import sys

source = pathlib.Path(sys.argv[1])
mirrors = [pathlib.Path(arg) for arg in sys.argv[2:]]


def compare(left, right):
    comparison = filecmp.dircmp(left, right)
    problems = []
    problems.extend(f"only in {left}: {name}" for name in comparison.left_only)
    problems.extend(f"only in {right}: {name}" for name in comparison.right_only)
    problems.extend(f"different: {left / name} != {right / name}" for name in comparison.diff_files)
    problems.extend(f"funny: {left / name} or {right / name}" for name in comparison.funny_files)
    for name in comparison.common_dirs:
        problems.extend(compare(left / name, right / name))
    return problems


for mirror in mirrors:
    if not mirror.exists():
        raise SystemExit(f"{mirror}: missing skill mirror")
    problems = compare(source, mirror)
    if problems:
        raise SystemExit("\n".join(problems))

print("Skill mirrors OK")
PY
}

check_stale_references() {
  # 廃止した docs / bridge / skill / mirror の名前が残ると、エージェントが
  # 存在しないファイルを読みに行って迷走する。歴史記述として旧名が残ってよいのは
  # Old/、docs/SOURCES.md、docs/EXECPLAN_*、docs/WORKLOG.md（作業履歴）、
  # docs/REQS.md（依頼の背景記述）だけに限定する。
  python3 - <<'PY'
import pathlib
import re

removed = [
    "ANTIGRAVITY.md", "KILO.md", "OPENCODE.md", "HUMAN.md", "llms.txt",
    "LLM_WIKI", "AGENT_BOOTSTRAP", "HANDOFF_PROTOCOL", "AI_AGENT_GUIDE",
    "COMPATIBILITY_GUIDE", "TOOL_PLAYBOOK", "BEST_PRACTICES_SOURCES",
    "DOCS_POLICY", "START_PROMPT", "docs/INDEX.md", "docs/PLANS.md",
    "agy-orchestration", "execplan-workflow", "context-triage", "docs-sync",
    "handoff-sync", "ship-check", "bootstrap-fast", "checkpoint-pack",
    "sync_shared_skills_to_claude", ".codex/skills", ".kilo/skills",
    ".kilo/commands", ".opencode/skills", ".opencode/commands",
    ".claude/commands", ".claude/rules",
]
pattern = re.compile("|".join(re.escape(name) for name in removed))

surfaces = [
    "AGENTS.md", "CLAUDE.md", "README.md", "SECURITY.md", "DESIGN.md",
    "kilo.jsonc", "opencode.jsonc",
    "docs/HARNESS.md", "docs/PROJECT_BRIEF.md",
    "docs/EXECPLAN_TEMPLATE.md",
    ".agents", ".claude", ".codex", ".cursor", ".kilo", ".opencode",
    ".agent-shared",
    "scripts/sync_shared_skills.py", "scripts/security_smoke.sh",
    "scripts/agent_loop.py",
]

problems = []
for surface in surfaces:
    base = pathlib.Path(surface)
    files = [base] if base.is_file() else sorted(p for p in base.rglob("*") if p.is_file())
    for path in files:
        # node_modules は Kilo / opencode CLI が実行時に .kilo/.opencode 配下へ
        # 自前 .gitignore 付きで生成する runtime 生成物。テンプレ配布物ではないため対象外
        if "__pycache__" in path.parts or "node_modules" in path.parts or path.suffix in {".pyc"}:
            continue
        # settings.local.json はユーザーローカルでテンプレ配布物ではないため対象外
        if path.name == "settings.local.json":
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for number, line in enumerate(text.splitlines(), start=1):
            match = pattern.search(line)
            if match:
                problems.append(f"{path}:{number}: stale reference {match.group(0)!r}")

if problems:
    raise SystemExit("\n".join(problems))

print("Stale references OK")
PY
}

run bash -n scripts/win_pwsh.sh
run bash -n scripts/win_codex.sh
run bash -n scripts/security_smoke.sh
run python3 -m json.tool kilo.jsonc
run python3 -m json.tool opencode.jsonc
run python3 -m json.tool .agents/hooks.json
run python3 -m json.tool .agents/plugins/codex-best-practice/plugin.json
run python3 -m json.tool .claude/settings.json
run python3 -m json.tool .cursor/hooks.json
run check_codex_config .codex/config.toml
run check_admin_policy
run check_cursor_policy
run bash scripts/security_smoke.sh
run env PYTHONPYCACHEPREFIX="$PYCACHE_DIR" python3 -m py_compile \
  .agent-shared/hooks_core/common.py \
  .agent-shared/hooks_core/runtime.py \
  .agents/skills/local-skill-bootstrap/scripts/init_skill.py \
  .agents/hooks/pre_invocation_context.py \
  .agents/hooks/pre_tool_use_policy.py \
  .codex/hooks/session_start_context.py \
  .codex/hooks/pre_tool_use_policy.py \
  .claude/hooks/session_start_context.py \
  .claude/hooks/pre_tool_use_policy.py \
  .cursor/hooks/pre_tool_use_policy.py \
  scripts/sync_shared_skills.py \
  scripts/agent_loop.py
# loop profile は frontmatter の構文と gates 必須制約を dry-run で検証する
run python3 scripts/agent_loop.py --profile .agent-shared/loops/security-review.md --dry-run
run python3 scripts/agent_loop.py --profile .agent-shared/loops/design-review.md --dry-run
run python3 scripts/agent_loop.py --profile .agent-shared/loops/TEMPLATE.md --dry-run
run python3 scripts/sync_shared_skills.py
run check_skill_metadata .agents/skills .claude/skills
run check_skill_mirrors .agents/skills .claude/skills
run check_stale_references

# 必須ファイル。ここに無いものが消えたら「テンプレとして配れない」ことを意味する。
for required in \
  README.md \
  AGENTS.md \
  CLAUDE.md \
  DESIGN.md \
  SECURITY.md \
  kilo.jsonc \
  opencode.jsonc \
  docs/HARNESS.md \
  docs/PROJECT_BRIEF.md \
  docs/REQS.md \
  docs/WORKLOG.md \
  docs/SOURCES.md \
  docs/EXECPLAN_TEMPLATE.md \
  scripts/win_pwsh.sh \
  scripts/win_codex.sh \
  scripts/security_smoke.sh \
  scripts/wsl_exec.ps1 \
  scripts/wsl_exec.cmd \
  scripts/sync_shared_skills.py \
  scripts/agent_loop.py \
  .agent-shared/loops/security-review.md \
  .agent-shared/loops/design-review.md \
  .agent-shared/loops/TEMPLATE.md \
  .agent-shared/hooks_core/__init__.py \
  .agent-shared/hooks_core/common.py \
  .agent-shared/hooks_core/runtime.py \
  .claude/settings.json \
  .claude/hooks/session_start_context.py \
  .claude/hooks/pre_tool_use_policy.py \
  .claude/agents/code-reviewer.md \
  .claude/agents/docs-maintainer.md \
  .claude/agents/test-debugger.md \
  .codex/config.toml \
  .codex/hooks/session_start_context.py \
  .codex/hooks/pre_tool_use_policy.py \
  .agents/hooks.json \
  .agents/hooks/pre_invocation_context.py \
  .agents/hooks/pre_tool_use_policy.py \
  .agents/plugins/codex-best-practice/plugin.json \
  .cursor/hooks.json \
  .cursor/hooks/pre_tool_use_policy.py \
  .kilo/agents/docs-maintainer.md \
  .kilo/agents/repo-reviewer.md \
  .kilo/agents/test-investigator.md \
  .opencode/agents/docs-maintainer.md \
  .opencode/agents/repo-reviewer.md \
  .opencode/agents/test-investigator.md
do
  if [[ ! -e "$required" ]]; then
    printf '[smoke] missing required file: %s\n' "$required" >&2
    exit 1
  fi
done

# canonical skill set。.claude/skills は mirror check が同一性まで担保する。
for skill in \
  start-task \
  execplan \
  checkpoint \
  karpathy-guidelines \
  security-harness \
  harness-loop \
  human-readable-writing \
  design-taste-frontend \
  local-skill-bootstrap
do
  if [[ ! -e ".agents/skills/$skill/SKILL.md" ]]; then
    printf '[smoke] missing required skill: %s\n' "$skill" >&2
    exit 1
  fi
done

# 廃止済み構造。復活したら v2 設計からの退行なので落とす。
for removed in \
  GEMINI.md \
  .gemini \
  ANTIGRAVITY.md \
  KILO.md \
  OPENCODE.md \
  HUMAN.md \
  llms.txt \
  docs/INDEX.md \
  docs/LLM_WIKI.md \
  docs/PLANS.md \
  docs/DOCS_POLICY.md \
  docs/START_PROMPT.txt \
  docs/AGENT_BOOTSTRAP.md \
  docs/HANDOFF_PROTOCOL.md \
  docs/AI_AGENT_GUIDE.md \
  docs/COMPATIBILITY_GUIDE.md \
  docs/TOOL_PLAYBOOK.md \
  docs/BEST_PRACTICES_SOURCES.md \
  .codex/skills \
  .kilo/skills \
  .kilo/commands \
  .opencode/skills \
  .opencode/commands \
  .claude/commands \
  .claude/rules \
  scripts/sync_shared_skills_to_claude.py
do
  if [[ -e "$removed" ]]; then
    printf '[smoke] removed v1 structure must not exist: %s\n' "$removed" >&2
    exit 1
  fi
done

run_optional_windows scripts/win_pwsh.sh '$PSVersionTable.PSVersion.ToString()'
run_optional_windows scripts/win_codex.sh --version
run_optional_windows cmd.exe /d /c scripts\\wsl_exec.cmd -Workdir "$ROOT" -Exec pwd

if command -v agy >/dev/null 2>&1; then
  run agy --version
else
  log "skip optional Antigravity CLI smoke: agy not found"
fi

log "smoke OK"
