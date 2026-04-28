#!/usr/bin/env python3

from __future__ import annotations

import pathlib
import re


DANGEROUS_COMMAND_PATTERNS = [
    r"\bgit\s+reset\s+--hard\b",
    r"\bgit\s+clean\s+-fd\b",
    r"\brm\s+-rf\s+/\b",
    r"\bsudo\s+rm\s+-rf\b",
    r"\bmkfs\b",
    r"\bdd\s+if=",
]

SECRET_FILE_BASENAMES = {
    ".env",
    ".env.local",
    ".env.production",
    ".env.development",
    ".npmrc",
    "id_rsa",
    "known_hosts",
    "credentials",
}

SECRET_PATH_PATTERNS = [
    r"(^|[ /])\.env($|[ .])",
    r"(^|[ /])\.env\.[A-Za-z0-9_-]+($|[ .])",
    r"\bid_rsa\b",
    r"\baws/credentials\b",
    r"\.pem\b",
    r"\.p12\b",
]

SECRET_SUFFIXES = (".pem", ".p12", ".key")
ALLOWED_SECRET_EXAMPLES = (".env.example", ".env.sample", ".env.template")

SHELL_TOOL_NAMES = {"Bash", "run_shell_command"}
WRITE_TOOL_NAMES = {"Edit", "Write", "write_file", "replace"}
SKILL_DIRECTORY_HINTS = (".agents/skills", ".claude/skills")
SKILL_DOWNLOAD_PATTERNS = [
    r"\bcurl\b",
    r"\bwget\b",
    r"\bgit\s+clone\b",
    r"\bgh\s+repo\s+clone\b",
]


def session_start_context() -> str:
    return (
        "初回 bootstrap では AGENTS.md と docs/AGENT_BOOTSTRAP.md を起点に、現在の user request と task に関係する project artifact を一次情報として扱い、docs/REQS.md を先に更新してから進めてください。"
        "docs/PROJECT_BRIEF.md や docs/WORKLOG.md が scaffold / stale なら、現在の repo 用に更新してから使ってください。"
        "小タスクは fast path として docs/PROJECT_BRIEF.md と更新済み docs/REQS.md だけ先に確認してください。"
        "再開時、高リスク、複雑変更では docs/INDEX.md、docs/WORKLOG.md、docs/HANDOFF_PROTOCOL.md を追加で確認してください。"
        "複雑な作業や複数モジュール横断の作業だけ docs/EXECPLAN_*.md を使ってください。"
        "繰り返し使う repo 固有 workflow が不足しているときは、ダウンロードより `.agents/skills/local-skill-bootstrap/` を使った local skill 作成を優先してください。"
        "WSL から Windows 側ツールを使うときは scripts/win_pwsh.sh と scripts/win_codex.sh を優先し、win_pwsh.sh は direct 優先で ssh は必要時だけ使ってください。"
        "Windows ネイティブから WSL コマンドを使うときは scripts/wsl_exec.cmd または scripts/wsl_exec.ps1 を使ってください。"
        "繰り返し手順は repo の skill / command を優先し、同じ長文を毎回書き直さないでください。"
        "回答と説明は原則日本語、途中経過は checkpoint のみ、.env や secrets には触れず、終了前に変更範囲を検証してください。"
    )


def _is_allowed_secret_example(value: str) -> bool:
    lowered = value.lower()
    return any(example in lowered for example in ALLOWED_SECRET_EXAMPLES)


def _extract_command(tool_input: dict) -> str:
    return str(tool_input.get("command") or tool_input.get("cmd") or "")


def _extract_path(tool_input: dict) -> str:
    candidates = [
        tool_input.get("file_path"),
        tool_input.get("path"),
        tool_input.get("target_file"),
        tool_input.get("target"),
    ]
    for candidate in candidates:
        if candidate:
            return str(candidate)
    return ""


def _command_violation(command: str) -> str | None:
    lowered = command.lower()

    for pattern in DANGEROUS_COMMAND_PATTERNS:
        if re.search(pattern, lowered):
            return "破壊的な shell コマンドはデフォルトで禁止です。必要ならユーザー確認を取ってください。"

    if any(skill_dir in lowered for skill_dir in SKILL_DIRECTORY_HINTS):
        for pattern in SKILL_DOWNLOAD_PATTERNS:
            if re.search(pattern, lowered):
                return "skill directory への外部ダウンロードは避け、`.agents/skills/local-skill-bootstrap/` で local skill を作成してください。"

    if not _is_allowed_secret_example(lowered):
        for pattern in SECRET_PATH_PATTERNS:
            if re.search(pattern, lowered):
                return "secret の可能性が高いファイルへのアクセスを禁止しました。sample や mask 済みの代替を使ってください。"

    return None


def _path_violation(path_value: str) -> str | None:
    if not path_value:
        return None

    lowered = path_value.lower()
    if _is_allowed_secret_example(lowered):
        return None

    basename = pathlib.Path(path_value).name
    if basename in SECRET_FILE_BASENAMES or basename.endswith(SECRET_SUFFIXES):
        return "secret の可能性が高いファイルの編集を禁止しました。example / sample だけを扱ってください。"

    return None


def evaluate_tool_use(tool_name: str, tool_input: dict) -> str | None:
    if tool_name in SHELL_TOOL_NAMES:
        return _command_violation(_extract_command(tool_input))

    if tool_name in WRITE_TOOL_NAMES:
        return _path_violation(_extract_path(tool_input))

    return None
