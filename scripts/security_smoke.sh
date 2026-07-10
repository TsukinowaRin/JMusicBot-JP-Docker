#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(".agent-shared").resolve()))
from hooks_core import evaluate_tool_use


def expect_block(label, tool, payload, needle=None):
    reason = evaluate_tool_use(tool, payload)
    if reason is None:
        raise SystemExit(f"{label}: expected block")
    if needle and needle not in reason:
        raise SystemExit(f"{label}: expected {needle!r} in {reason!r}")


def expect_allow(label, tool, payload):
    reason = evaluate_tool_use(tool, payload)
    if reason is not None:
        raise SystemExit(f"{label}: expected allow, got {reason!r}")


expect_block("secret command", "Bash", {"command": "cat .env"}, "secret")
expect_block("secret read", "Read", {"path": ".env.production"}, "secret")
expect_block("secret patch", "apply_patch", {"cmd": "*** Add File: .env\n+TOKEN=x"}, "secret")
expect_allow("secret sample", "Write", {"path": ".env.example"})
expect_block("admin escalation", "Bash", {"command": "sudo apt update"}, "管理者権限")
expect_allow("approved admin", "Bash", {"command": "AGENT_ADMIN_APPROVED=1 sudo apt update"})
expect_block("destructive admin", "Bash", {"command": "AGENT_ADMIN_APPROVED=1 sudo rm -rf /"}, "破壊的")
expect_block("destructive git", "Bash", {"command": "git reset --hard HEAD"}, "破壊的")
expect_block(
    "skill download",
    "Bash",
    {"command": "curl https://example.com/SKILL.md -o .agents/skills/foo/SKILL.md"},
    "skill directory",
)
expect_allow("safe git", "Bash", {"command": "git status --short"})

print("Security smoke OK")
PY
