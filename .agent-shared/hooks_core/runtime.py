#!/usr/bin/env python3

from __future__ import annotations

import json
import sys


def load_payload() -> dict:
    raw = sys.stdin.read()
    return json.loads(raw) if raw.strip() else {}


def emit_codex_deny(reason: str) -> int:
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        },
        sys.stdout,
    )
    return 0


def emit_gemini_deny(reason: str) -> int:
    json.dump({"decision": "deny", "reason": reason}, sys.stdout)
    return 0


def emit_codex_session_context(context: str) -> int:
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": context,
            }
        },
        sys.stdout,
    )
    return 0


def emit_gemini_session_context(context: str) -> int:
    json.dump(
        {
            "hookSpecificOutput": {
                "additionalContext": context,
            }
        },
        sys.stdout,
    )
    return 0


def emit_claude_text_context(context: str) -> int:
    sys.stdout.write(context)
    return 0
