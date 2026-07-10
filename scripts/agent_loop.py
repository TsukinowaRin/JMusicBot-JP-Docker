#!/usr/bin/env python3
"""自己ループ runner: 「続けて」なしで goal 達成まで headless CLI を反復起動する。

設計の背景（docs/EXECPLAN_2026-07-07_loop-harness.md）:
- headless CLI は 1 回の起動で 1 chunk しか進まないことが多く、人間が毎回
  「続けて」と入力する必要があった。この runner がその再起動を代行する。
- 進行 state はエージェント自身が docs/WORKLOG.md / docs/REQS.md に書く
  （docs = working memory 原則）。runner は実行ログを .loop/ に残すだけで、
  独自の state 形式を持たない。毎 iteration は fresh context の headless 起動
  なので、中断してもコマンド再実行だけで docs から続きになる。
- 安全策: hooks / permission ガードが効いたままの headless モードだけを使う。
  push / merge は行わない。停止条件（DONE+gates / BLOCKED / max / stall）を
  必ず持ち、無限ループと同一失敗の繰り返しを機械的に止める。

使い方:
  python3 scripts/agent_loop.py --profile .agent-shared/loops/security-review.md --cli codex
  python3 scripts/agent_loop.py --profile <p> --agent-cmd "kilo run -m kilo/kilo-auto/free"
  python3 scripts/agent_loop.py --profile <p> --dry-run
"""

import argparse
import datetime
import hashlib
import re
import shlex
import shutil
import subprocess
import sys
from pathlib import Path

# 各 CLI の headless 起動形。auto-approve は「編集を承認する」水準までにし、
# hooks / permission の deny はそのまま効く（安全策はガード層に委ねる）。
# prompt の渡し方: claude は flag が prompt を食う事故があるため stdin、他は末尾 argv。
CLI_PRESETS = {
    "claude": {"cmd": ["claude", "-p", "--permission-mode", "acceptEdits"], "stdin": True},
    "codex": {"cmd": ["codex", "exec", "--full-auto", "--skip-git-repo-check"], "stdin": False},
    "agy": {"cmd": ["agy", "--add-dir", ".", "-p"], "stdin": False},
    "opencode": {"cmd": ["opencode", "run"], "stdin": False},
    "kilo": {"cmd": ["kilo", "run"], "stdin": False},
    "cursor": {"cmd": ["cursor-agent", "-p", "--trust"], "stdin": False},
}

# 行頭アンカー必須。prompt 例示や本文中の言及を status と誤認しないため、
# テンプレート側も regex に一致しない書き方（<CONTINUE | ...> 形式）で例示している。
STATUS_RE = re.compile(r"^\s*LOOP_STATUS:\s*(CONTINUE|DONE|BLOCKED)\b:?\s*(.*)$", re.IGNORECASE | re.MULTILINE)

PROMPT_TEMPLATE = """あなたは自動ループ harness（scripts/agent_loop.py）の iteration {iteration}/{max_iterations} として起動された。
人間は介入できない。次の手順で今回の 1 chunk だけを進めること。

1. docs/REQS.md と docs/WORKLOG.md（あれば）を読み、下の GOAL の未完了部分を特定する。
2. 15〜30分相当の 1 chunk だけ実装・修正し、変更には最小の検証を添える。
3. docs/WORKLOG.md の「現在の状態」を、次の iteration が chat 履歴なしで続きから再開できるように更新する。
4. 出力の最後に、必ず次の形式の 1 行を出力する（山括弧 <> は付けず、値を1つ選ぶ）:
   LOOP_STATUS: <CONTINUE | DONE | BLOCKED: 人間の判断が必要な理由>
   CONTINUE = 未完了の作業が残っている / DONE = 受け入れ条件を全て満たした /
   BLOCKED = 人間の判断・権限・情報が無いと進めない

DONE は GOAL の受け入れ条件を全て満たし、下の GATES が全て pass すると確信できる時だけ出力する。
同じ試行を繰り返さない。前回と同じ失敗が見えたら、原因仮説を変えてから手を動かす。

== GATES（runner が機械的に実行する完了判定）==
{gates_text}
{feedback_section}
== GOAL ==
{goal}
"""


def parse_profile(path: Path) -> dict:
    """markdown + 簡易 frontmatter を読む。YAML パーサ非依存（外部依存ゼロ制約）。

    対応する形:
      ---
      name: security-review
      max_iterations: 8
      gates:
        - bash scripts/security_smoke.sh
      ---
      <goal 本文>
    """
    text = path.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.DOTALL)
    if not m:
        raise SystemExit(f"{path}: frontmatter (--- ... ---) がありません")
    header, body = m.group(1), m.group(2)

    profile = {
        "name": path.stem,
        "max_iterations": 8,
        "stall_limit": 2,
        "iteration_timeout": 1800,
        "gate_timeout": 600,
        "gates_every_iteration": False,
        "gates": [],
        "goal": body.strip(),
    }
    current_list = None
    for line in header.splitlines():
        if not line.strip() or line.strip().startswith("#"):
            continue
        item = re.match(r"^\s+-\s+(.*)$", line)
        if item and current_list is not None:
            profile[current_list].append(item.group(1).strip())
            continue
        kv = re.match(r"^([A-Za-z_]+):\s*(.*)$", line)
        if not kv:
            raise SystemExit(f"{path}: frontmatter を解釈できない行: {line!r}")
        key, value = kv.group(1), kv.group(2).strip()
        if key == "gates":
            current_list = "gates"
            continue
        current_list = None
        if key in {"max_iterations", "stall_limit", "iteration_timeout", "gate_timeout"}:
            profile[key] = int(value)
        elif key == "gates_every_iteration":
            profile[key] = value.lower() in {"true", "1", "yes"}
        elif key == "name":
            profile[key] = value
        else:
            raise SystemExit(f"{path}: 未対応の frontmatter key: {key}")
    if not profile["gates"]:
        raise SystemExit(f"{path}: gates が空です。検証不能な loop は回さない（harness-loop skill 参照）")
    return profile


def workspace_hash(workdir: Path) -> str | None:
    """stall 検出用に working tree の指紋を取る。git repo でなければ None（stall 検出 skip）。"""
    try:
        parts = []
        for args in (["git", "rev-parse", "HEAD"], ["git", "status", "--porcelain"], ["git", "diff"]):
            r = subprocess.run(args, cwd=workdir, capture_output=True, text=True, timeout=60)
            if r.returncode != 0 and args[1] == "rev-parse":
                parts.append("")  # commit ゼロの直後でも status/diff だけで比較できるようにする
                continue
            parts.append(r.stdout)
        return hashlib.sha256("\x00".join(parts).encode()).hexdigest()
    except (OSError, subprocess.TimeoutExpired):
        return None


def run_gates(gates: list[str], workdir: Path, timeout: int) -> list[tuple[str, int, str]]:
    """各 gate を実行し (command, returncode, 出力末尾) を返す。"""
    results = []
    for gate in gates:
        try:
            r = subprocess.run(
                gate, shell=True, cwd=workdir, capture_output=True, text=True, timeout=timeout
            )
            output = (r.stdout + r.stderr)[-2000:]
            results.append((gate, r.returncode, output))
        except subprocess.TimeoutExpired:
            results.append((gate, 124, f"timeout ({timeout}s)"))
    return results


def build_feedback(gate_results: list[tuple[str, int, str]]) -> str:
    failed = [(g, c, o) for g, c, o in gate_results if c != 0]
    if not failed:
        return ""
    lines = ["", "== 前回 iteration の gate 失敗（最優先で修正すること）=="]
    for gate, code, output in failed:
        lines.append(f"$ {gate}  (exit {code})")
        lines.append(output.strip()[-1500:])
    lines.append("")
    return "\n".join(lines)


def parse_status(output: str) -> tuple[str | None, str]:
    matches = STATUS_RE.findall(output)
    if not matches:
        return None, ""
    status, reason = matches[-1]
    return status.upper(), reason.strip()


def main() -> int:
    parser = argparse.ArgumentParser(description="goal 達成まで headless CLI を自己ループさせる runner")
    parser.add_argument("--profile", required=True, help=".agent-shared/loops/ の loop profile")
    parser.add_argument("--cli", choices=sorted(CLI_PRESETS), help="CLI preset")
    parser.add_argument("--agent-cmd", help="preset の代わりに使う起動コマンド（prompt は末尾 argv で渡す）")
    parser.add_argument("--workdir", default=".", help="loop を回す workspace（default: カレント）")
    parser.add_argument("--max-iterations", type=int, help="profile の max_iterations を上書き")
    parser.add_argument("--dry-run", action="store_true", help="CLI を起動せず構成検証だけ行う")
    args = parser.parse_args()

    if not args.dry_run and not args.cli and not args.agent_cmd:
        parser.error("--cli か --agent-cmd のどちらかが必要です（--dry-run 時は省略可）")
    if args.cli and args.agent_cmd:
        parser.error("--cli と --agent-cmd は同時に指定できません")

    workdir = Path(args.workdir).resolve()
    if not workdir.is_dir():
        raise SystemExit(f"workdir がありません: {workdir}")
    profile = parse_profile(Path(args.profile).resolve())
    if args.max_iterations:
        profile["max_iterations"] = args.max_iterations

    if args.agent_cmd:
        agent_cmd, use_stdin = shlex.split(args.agent_cmd), False
    elif args.cli:
        preset = CLI_PRESETS[args.cli]
        agent_cmd, use_stdin = list(preset["cmd"]), preset["stdin"]
    else:
        agent_cmd, use_stdin = [], False

    gates_text = "\n".join(f"- {g}" for g in profile["gates"])

    if args.dry_run:
        print(f"profile: {profile['name']}")
        print(f"workdir: {workdir}")
        print(f"max_iterations={profile['max_iterations']} stall_limit={profile['stall_limit']} "
              f"iteration_timeout={profile['iteration_timeout']}s "
              f"gates_every_iteration={profile['gates_every_iteration']}")
        print(f"agent: {' '.join(agent_cmd) or '(未指定)'}" + ("  [prompt=stdin]" if use_stdin else ""))
        print("gates:")
        for g in profile["gates"]:
            print(f"  - {g}")
        if agent_cmd and shutil.which(agent_cmd[0]) is None:
            print(f"warning: {agent_cmd[0]} が PATH にありません", file=sys.stderr)
        print("goal（先頭 5 行）:")
        for line in profile["goal"].splitlines()[:5]:
            print(f"  {line}")
        print("dry-run OK")
        return 0

    if shutil.which(agent_cmd[0]) is None:
        raise SystemExit(f"{agent_cmd[0]} が PATH にありません")

    run_id = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    log_dir = workdir / ".loop" / profile["name"] / run_id
    log_dir.mkdir(parents=True, exist_ok=True)

    feedback = ""
    prev_hash = workspace_hash(workdir)
    stall_count = 0
    missing_status_count = 0

    for iteration in range(1, profile["max_iterations"] + 1):
        prompt = PROMPT_TEMPLATE.format(
            iteration=iteration,
            max_iterations=profile["max_iterations"],
            gates_text=gates_text,
            feedback_section=feedback,
            goal=profile["goal"],
        )
        print(f"\n=== iteration {iteration}/{profile['max_iterations']} ({profile['name']}) ===", flush=True)
        cmd = agent_cmd if use_stdin else agent_cmd + [prompt]
        try:
            # stdin を使わない CLI には DEVNULL を渡す。親 stdin を継承させると、
            # CLI が対話確認（trust / login 等）を出した時に timeout まで無言でハングする
            r = subprocess.run(
                cmd,
                cwd=workdir,
                input=prompt if use_stdin else None,
                stdin=None if use_stdin else subprocess.DEVNULL,
                capture_output=True,
                text=True,
                timeout=profile["iteration_timeout"],
            )
            output = r.stdout + ("\n" + r.stderr if r.stderr.strip() else "")
        except subprocess.TimeoutExpired:
            output = f"(iteration timeout {profile['iteration_timeout']}s)"

        log_file = log_dir / f"iter-{iteration:02d}.log"
        log_file.write_text(f"== prompt ==\n{prompt}\n\n== output ==\n{output}\n", encoding="utf-8")

        status, reason = parse_status(output)
        print(f"status: {status or '(なし)'} {reason}".rstrip(), flush=True)

        if status is None:
            # 契約行が無い出力は「壊れた iteration」。1 回は継続扱いで様子を見るが、
            # 連続したら CLI 側の異常（認証切れ、flag 誤り等）なので人間に返す。
            missing_status_count += 1
            if missing_status_count >= 2:
                print(f"停止: LOOP_STATUS が {missing_status_count} 回連続で欠落。log: {log_file}")
                return 4
            status = "CONTINUE"
        else:
            missing_status_count = 0

        if status == "BLOCKED":
            print(f"停止: BLOCKED — {reason or '理由未記載'}。log: {log_file}")
            return 2

        gate_results = []
        if status == "DONE" or profile["gates_every_iteration"]:
            gate_results = run_gates(profile["gates"], workdir, profile["gate_timeout"])
            for gate, code, _ in gate_results:
                print(f"gate: {'pass' if code == 0 else f'FAIL(exit {code})'}  {gate}", flush=True)

        if status == "DONE":
            if all(code == 0 for _, code, _ in gate_results):
                print(f"\n成功: DONE + gates 全 pass（{iteration} iterations）。log: {log_dir}")
                return 0
            # DONE 宣言でも gate が落ちたら受理しない。失敗内容を次 iteration に渡す。
            feedback = build_feedback(gate_results)
            continue

        feedback = build_feedback(gate_results)

        cur_hash = workspace_hash(workdir)
        if cur_hash is not None and cur_hash == prev_hash:
            stall_count += 1
            if stall_count >= profile["stall_limit"]:
                print(f"停止: workspace が {stall_count} iteration 連続で無変化（stall）。log: {log_dir}")
                return 3
        else:
            stall_count = 0
        prev_hash = cur_hash

    print(f"\n停止: max_iterations ({profile['max_iterations']}) に到達。log: {log_dir}")
    return 5


if __name__ == "__main__":
    sys.exit(main())
