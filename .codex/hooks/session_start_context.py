#!/usr/bin/env python3

from __future__ import annotations

import pathlib
import sys


def _load_shared_module() -> None:
    project_root = pathlib.Path(__file__).resolve().parents[2]
    sys.path.insert(0, str(project_root / ".agent-shared"))


def main() -> int:
    _load_shared_module()
    from hooks_core import emit_codex_session_context, session_start_context

    return emit_codex_session_context(session_start_context())


if __name__ == "__main__":
    raise SystemExit(main())
