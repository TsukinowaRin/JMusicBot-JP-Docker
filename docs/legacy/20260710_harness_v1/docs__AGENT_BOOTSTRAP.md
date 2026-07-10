# エージェント初期化ガイド

この `docs/` は、プロジェクトの文脈、CLI ごとの入口、handoff ルールを docs だけで把握できるように設計している。

## 最小起動フレーズ

ユーザーが初回に「DocsとAGENTS.mdを読んで」と言ったら、それだけで bootstrap を開始してよい。

その場合の期待動作:

1. `AGENTS.md` を読む
2. この `docs/AGENT_BOOTSTRAP.md` を読む
3. 現在の user request と、その task に関係する project artifact を主タスクの一次情報として扱う
4. `docs/REQS.md` を現在の依頼で上書きする
5. task size を small / medium / deep に分類する
6. `docs/PROJECT_BRIEF.md` や `docs/WORKLOG.md` が scaffold / stale なら、現在の repo 用に更新する
7. 必要な docs を追加で読む
8. 必要なら `docs/EXECPLAN_*.md` を作る
9. 実装、検証、docs 更新まで自走する

このフレーズは「説明を読むだけで止まる」意味ではなく、「repo の運用ルールを取り込んで作業を始める」意味として扱う。
テンプレート由来の stale な `docs/REQS.md` や `docs/PROJECT_BRIEF.md` が current user request や task に関係する project artifact と衝突する場合は、現在の依頼と現物が優先される。

## 初回セッションの読む順序

### Fast path

小タスク、単一ファイル修正、限定調査では、まず次だけ読む。

1. `docs/PROJECT_BRIEF.md`
   - 入口と build/test/run を把握する
   - まだ scaffold のままなら、repo 実態で最低限更新する
2. `docs/REQS.md`
   - 今回の要求と acceptance criteria を確認する
   - ただし最初に current user request で更新してから使う

必要になったときだけ `rg` / `sed` で周辺コードや docs を狭く読む。`docs/` 全読はしない。

### Deep path

handoff 再開、複数モジュール横断、高リスク変更、履歴依存の調査では次を読む。

1. `docs/PROJECT_BRIEF.md`
2. `docs/REQS.md`
3. `docs/TOOL_PLAYBOOK.md`
4. `docs/WORKLOG.md`
5. `docs/HANDOFF_PROTOCOL.md`

## 必要時に読む参照文書

- `docs/AI_AGENT_GUIDE.md`
  - AGENTS / CLAUDE / GEMINI / hooks / skills / agents の役割分担
- `docs/COMPATIBILITY_GUIDE.md`
  - Claude / Codex / Gemini の互換方針
- `docs/PLANS.md`, `docs/EXECPLAN_TEMPLATE.md`, `docs/EXECPLAN_*.md`
  - 複雑作業の計画と実行
- `docs/DOCS_POLICY.md`
  - docs の更新ルール
- `docs/START_PROMPT.txt`
  - 新規セッションを始めるときの短い起動文

## CLI ごとの入口

- Codex
  - 永続ルール: `AGENTS.md`
  - hooks / policy: `.codex/config.toml`, `.codex/hooks.json`, `.codex/rules/`
  - repo skills: `.agents/skills/`
- Claude Code
  - 永続ルール: `CLAUDE.md`, `.claude/rules/`
  - hooks: `.claude/settings.json`
  - reusable workflows: `.claude/skills/`
  - specialized workers: `.claude/agents/`
- Gemini CLI
  - 永続ルール: `GEMINI.md`
  - workspace settings: `.gemini/settings.json` (`context.fileName = ["AGENTS.md", "GEMINI.md"]`, model pin なし)
  - repeatable prompts: `.gemini/commands/`
  - workspace skills: `.agents/skills/`
  - custom agents: `.gemini/agents/`

## 再利用ワークフロー

- Codex / Gemini CLI
  - task の大きさ判定には `.agents/skills/context-triage/`
- Claude Code
  - fast bootstrap には `.claude/commands/bootstrap-fast.md`
  - checkpoint 整理には `.claude/commands/checkpoint-pack.md`
- Gemini CLI
  - fast bootstrap には `.gemini/commands/bootstrap-fast.toml`
  - checkpoint 整理には `.gemini/commands/checkpoint-pack.toml`
  - 文脈の棚卸しには `.gemini/commands/context-audit.toml`

## WSL から Windows 側ツールを使う入口

- PowerShell コマンドを 1 行で実行したい場合
  - `scripts/win_pwsh.sh '<pwsh-script>'`
- `.ps1` を実行したい場合
  - `scripts/win_pwsh.sh --file <path-to-ps1> [args...]`
- Windows 側 `codex` を使いたい場合
  - `scripts/win_codex.sh <codex-args...>`
- Windows 側から WSL コマンドを実行したい場合
  - `.\scripts\wsl_exec.ps1 -Workdir <wsl-or-windows-path> -Exec <command> [args...]`
  - `.\scripts\wsl_exec.cmd -Workdir <wsl-or-windows-path> -Exec <command> [args...]`
- 詳細な使い分けと制約は `docs/TOOL_PLAYBOOK.md` を参照する

## 共通のふるまい

- 回答、説明、レビュー、要約、作業ログは原則日本語で行う
- 結論 -> 理由 -> 手順で返す
- 不確実な点は仮定を明記する
- model は原則 default / Auto で使い、比較検証や障害切り分けのときだけ明示指定する
- 途中経過の逐次報告は避け、必要な報告はチェックポイントに絞る
- 既存コードと既存 docs を先に確認する
- 変更箇所に対して最小で十分な検証を行う
- secrets や `.env` 実体には触れない
- 破壊的コマンドは明示要求なしに使わない
- どの停止点でも、別エージェントが `docs` だけで再開できる状態を保つ

## 初期化後

2回目以降は `docs/INDEX.md` を起点に必要箇所だけ読む。fast path で足りる限り、deep path へ自動的に広げない。
Gemini CLI では、session が重く感じたら `context-audit` と `/stats` を使って、広げすぎた文脈を点検する。
