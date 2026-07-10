#!/usr/bin/env python3

from __future__ import annotations

import pathlib
import sys


def _load_shared_module() -> None:
    project_root = pathlib.Path(__file__).resolve().parents[2]
    sys.path.insert(0, str(project_root / ".agent-shared"))


def main() -> int:
    _load_shared_module()
    from hooks_core import emit_antigravity_deny, evaluate_tool_use, load_payload

    payload = load_payload()
    tool_call = payload.get("toolCall", {})
    reason = evaluate_tool_use(tool_call.get("name", ""), tool_call.get("args", {}))
    if reason:
        return emit_antigravity_deny(reason)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
