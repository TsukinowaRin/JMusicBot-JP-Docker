# AI エージェント運用ガイド

## 役割分担の見取り図

- ルール
  - `AGENTS.md`: 共通の永続ルール
  - `CLAUDE.md`: Claude Code 用の追加ルール
  - `GEMINI.md`: Gemini CLI 用の追加ルール
  - `.claude/rules/`, `.codex/rules/`: CLI 固有の rule 補助
- 実行時ガード
  - `.codex/hooks.json`, `.claude/settings.json`, `.gemini/settings.json`: hook 設定
  - `.agent-shared/hooks_core/`: CLI 間で共有する hook ロジック本体
- 再利用ワークフロー
  - `.agents/skills/`: 共通 canonical source
  - `.claude/skills/`: Claude 用 mirror
  - `.claude/commands/`: Claude 用 workflow command
  - `.gemini/commands/`: Gemini 用の定型 prompt
  - `.agents/skills/local-skill-bootstrap/`: 足りない reusable workflow を repo local skill として生やすための共通 skill
- 役割特化エージェント
  - `.claude/agents/`, `.gemini/agents/`
- 作業 docs
  - `docs/REQS.md`: 現在の要求
  - `docs/EXECPLAN_*.md`: 複雑作業の実行計画
  - `docs/WORKLOG.md`: 直近の停止点
  - `docs/HANDOFF_PROTOCOL.md`: handoff の最低基準
- WSL から Windows 側ツールを使う wrapper
  - `scripts/win_pwsh.sh`: PowerShell 用の共通入口。inline / `--file` の両対応
  - `scripts/win_codex.sh`: Windows 側 `codex` 用の入口
  - `scripts/wsl_exec.ps1`: Windows 側 PowerShell から WSL repo / Linux toolchain を呼ぶ入口
  - `scripts/wsl_exec.cmd`: Windows 側 `cmd` ベースから WSL repo / Linux toolchain を呼ぶ入口

## 言語方針

- 人間向けの説明、回答、レビュー、要約、ドキュメント更新は原則日本語で行う。
- ユーザーが明示的に英語などを指定した場合のみ切り替える。
- コード、設定キー、識別子、コマンド、外部ツールが要求する frontmatter は原文のままでもよい。

## 互換性方針

- skills は `.agents/skills/` を共通 canonical source とし、Claude 用は同じ `SKILL.md` subset にそろえる。
- 新しい shared skill を作るときは、まず `.agents/skills/local-skill-bootstrap/` を使って local 作成を試みる。
- hooks は `.agent-shared/hooks_core/` に共通ロジックを置き、各 CLI の adapter から呼び出す。
- fast bootstrap の意図は `context-triage` skill と Claude / Gemini commands でそろえる。
- Gemini は project memory を持てるぶん、`GEMINI.md` と `.gemini/settings.json` は短く保ち、必要なら `context-audit` で点検する。
- project-level の既定 model は Codex / Claude Code / Gemini CLI のいずれも pin せず、default / Auto に任せる。
- 詳細は `docs/COMPATIBILITY_GUIDE.md` を参照する。

## 推奨フロー

1. 初回セッションではまず task size を見て fast path / deep path を選ぶ
2. まず current task を `docs/REQS.md` に正規化し、以後は `docs/INDEX.md` と更新済み `docs/REQS.md` を起点に必要箇所を読む
3. 複雑作業なら `docs/EXECPLAN_*.md` を作る
4. root instructions と rules に従って実装する
5. skills / subagents / commands は必要なときだけ使う
   - 繰り返し現れる repo 固有 workflow は `.agents/skills/local-skill-bootstrap/` で skill 化する
6. hooks / rules は安全ガードとして扱う
7. 検証結果を docs に戻す
8. 停止前に `docs/WORKLOG.md` と必要なら `docs/EXECPLAN_*.md` を更新し、handoff-ready にする
9. Windows 側 PowerShell や `codex` が必要な場合は、直接 `pwsh.exe` を決め打ちせず `scripts/win_pwsh.sh` / `scripts/win_codex.sh` を優先する
10. Windows ネイティブ側から WSL コマンドが必要な場合は `scripts/wsl_exec.ps1` または `scripts/wsl_exec.cmd` を優先する
11. Gemini CLI では、memory / commands / agents / skills を更新したあとに必要なら reload を使い、session が重い場合は `/stats` を確認する
