#!/usr/bin/env python3

from __future__ import annotations

import pathlib
import shutil
import time
from contextlib import contextmanager


# v2 では mirror は Claude Code 用の 1 本だけにする。Codex / Antigravity / Cursor /
# opencode / Kilo Code は `.agents/skills/` を native に読むため（出典は
# docs/SOURCES.md）、mirror を増やすと drift リスクと保守コストだけが増える。
# Claude Code が AGENTS.md / .agents/skills を native 対応したら、この script ごと
# 廃止してよい。
MIRROR_ROOTS = (".claude/skills",)


@contextmanager
def skill_sync_lock(repo_root: pathlib.Path):
    lock_dir = repo_root / "tmp" / ".skill-sync.lock"
    lock_dir.parent.mkdir(exist_ok=True)

    # Mirror sync deletes and recreates target directories. If smoke and a
    # manual sync run at the same time, one process can observe a half-written
    # mirror and fail. A directory lock keeps the operation portable and avoids
    # adding an external dependency.
    for _ in range(600):
        try:
            lock_dir.mkdir()
            break
        except FileExistsError:
            try:
                if time.time() - lock_dir.stat().st_mtime > 600:
                    lock_dir.rmdir()
                    continue
            except OSError:
                pass
            time.sleep(0.1)
    else:
        raise TimeoutError(f"timed out waiting for skill sync lock: {lock_dir}")

    try:
        yield
    finally:
        try:
            lock_dir.rmdir()
        except OSError:
            pass


def sync_tree(source_root: pathlib.Path, target_root: pathlib.Path) -> None:
    # `.agents/skills` stays the only hand-edited source so agents do not drift
    # by CLI. WSL + Windows ドライブ (drvfs) では symlink が壊れやすいため、
    # 参照ではなくコピー同期にしている。
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


def main() -> int:
    repo_root = pathlib.Path(__file__).resolve().parents[1]
    source_root = repo_root / ".agents" / "skills"

    with skill_sync_lock(repo_root):
        for mirror in MIRROR_ROOTS:
            sync_tree(source_root, repo_root / mirror)

    print("Synced shared skills into " + ", ".join(MIRROR_ROOTS))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
