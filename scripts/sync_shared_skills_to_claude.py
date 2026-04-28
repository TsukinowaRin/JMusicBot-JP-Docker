#!/usr/bin/env python3

from __future__ import annotations

import pathlib
import shutil


def main() -> int:
    repo_root = pathlib.Path(__file__).resolve().parents[1]
    source_root = repo_root / ".agents" / "skills"
    target_root = repo_root / ".claude" / "skills"
    source_names = set()

    for source_dir in sorted(source_root.iterdir()):
        if not source_dir.is_dir():
            continue
        if not (source_dir / "SKILL.md").exists():
            continue
        skill_name = source_dir.name
        source_names.add(skill_name)
        target_dir = target_root / skill_name
        if target_dir.exists():
            shutil.rmtree(target_dir)
        shutil.copytree(source_dir, target_dir)

    if target_root.exists():
        for target_dir in sorted(target_root.iterdir()):
            if not target_dir.is_dir():
                continue
            if target_dir.name in source_names:
                continue
            shutil.rmtree(target_dir)

    print("Synced shared skills into .claude/skills")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
