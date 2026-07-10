---
name: harness-loop
description: Harness / loop engineering を使い、長いAIエージェント作業を状態、制約、品質ゲート、停止条件つきの反復に分解するときに使う。「続けて」なしで goal 達成まで自己ループさせる runner（scripts/agent_loop.py）の使い方を含む。複数エージェント、長時間実行、定期運用、失敗回復が必要な作業向け。
---

# Harness Loop

## 使う場面

- medium / deep task が複数セッション、複数エージェント、または長時間実行にまたがる。
- 同じ作業を定期的に回したいが、毎回の手作業プロンプトに依存したくない。
- 「作った」ではなく、検証、レビュー、停止条件、handoff まで含めて閉じたい。

小さい単発修正では使わない。まず `start-task` と `karpathy-guidelines` を優先する。

## Loop Contract

作業前に、以下を `docs/REQS.md` または `docs/EXECPLAN_*.md` に明示する。

1. State: 進行状態を置くファイル。例: `docs/WORKLOG.md`、対象 ExecPlan。
2. Constraints: 触ってよい範囲、禁止コマンド、secret、予算、時間上限。
3. Inputs: 最初に読む docs / code / issue / spec。
4. Actions: 1 loop で実行する最小手順。例: 調査 -> 小変更 -> 最小検証。
5. Gates: loop ごとに必ず通す test / lint / smoke / review。
6. Stop: 成功、失敗、確認待ち、予算切れの条件。
7. Handoff: 次のエージェントが読む文書と最初のコマンド。

## 推奨 Loop

1. 要求を 1 文の goal と受け入れ条件に圧縮する。
2. 作業を 15-30 分以内の chunk に切る。
3. chunk ごとに、変更前の前提、変更内容、実行した検証を state に残す。
4. 実装 agent と review / verification agent を分けられる場合は分ける。
5. 失敗が 2 回続いたら、同じ試行を繰り返さず、原因仮説と次の検証を state に書く。
6. 成功後は `checkpoint` を使い、diff、検証、残リスク、Go/No-Go をまとめる。

## 自己ループ runner（scripts/agent_loop.py）

「続けて」と毎回入力する代わりに、headless CLI を goal 達成まで自動で再起動する。
Loop Contract の実行形で、state は docs（WORKLOG / REQS）、gates と停止条件は profile に置く。

```bash
# profile 駆動で回す（CLI preset: claude / codex / agy / opencode / kilo / cursor）
python3 scripts/agent_loop.py --profile .agent-shared/loops/security-review.md --cli codex

# 起動コマンドを自由指定する場合（prompt は末尾 argv で渡される）
python3 scripts/agent_loop.py --profile <p> --agent-cmd "kilo run -m kilo/kilo-auto/free"

# CLI を起動せず構成だけ検証
python3 scripts/agent_loop.py --profile <p> --dry-run
```

- profile は `.agent-shared/loops/` に置く。`security-review.md` / `design-review.md` が同梱済みで、
  新しい loop は `TEMPLATE.md` をコピーして作る。gates（機械実行できる完了判定）は必須。
- 各 iteration は fresh context の headless 起動。エージェントは docs/WORKLOG.md を更新してから
  `LOOP_STATUS: CONTINUE / DONE / BLOCKED` を宣言する。DONE は gates 全 pass の時だけ受理される。
- 停止条件: DONE+gates pass（exit 0）/ BLOCKED（2）/ workspace 無変化の stall（3）/
  契約行の連続欠落（4）/ max_iterations 到達（5）。実行ログは `.loop/`（gitignore 済み）。
- 安全策: hooks / permission の deny は headless でも効いたまま。runner は push / merge をしない。

## Quality Gates

- Deterministic gate を優先する。例: unit test、lint、type-check、smoke、schema validation。
- prompt だけで守れない制約は hook、permission、script、CI、MCP server など外側で止める。
- subagent review は「仕様適合」と「コード品質」を分ける。
- 自動 loop では auto-merge を既定にしない。release / push は明示条件を満たした時だけ行う。

## Anti-patterns

- 状態を chat 履歴だけに置く。
- 成功条件を「良い感じ」など検証不能な言葉にする。
- 毎回 docs 全読を強制して token を浪費する。
- 失敗時に同じ command / prompt を根拠なく再実行する。
- 長い process を always-on instructions に貼り付ける。
