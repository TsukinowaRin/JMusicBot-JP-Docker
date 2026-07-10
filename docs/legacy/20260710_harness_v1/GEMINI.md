@AGENTS.md
@docs/AGENT_BOOTSTRAP.md

# Gemini CLI 向け補足

- このファイルを、project-level の Gemini context file として使う。
- このファイルは短く保ち、Gemini の project memory に不要な詳細を詰め込まない。
- 回答、説明、レビュー、作業ログは原則日本語で行う。ユーザーが明示的に他言語を指定した場合のみ切り替える。
- 途中経過の逐次報告は避け、必要な報告はチェックポイントに絞る。
- ワークフロー、ツール利用、プロジェクト慣例は `docs/` を優先して参照する。
- 繰り返し使う bootstrap や ship-check には `.gemini/commands/` を使う。小タスクでは `bootstrap-fast.toml`、文脈が重いときは `context-audit.toml` を優先する。
- project-level では model を pin しない。Gemini CLI の default / Auto を使い、必要なときだけ `--model ...` や `GEMINI_MODEL=...` で手動 override する。
- 実際にどの model が選ばれたか曖昧なときは `/about` で effective model を確認する。比較検証や障害切り分けのときだけ明示 model を使う。
- Gemini 固有の補足はここに置き、共通ルールは `AGENTS.md` に集約する。
- WSL から Windows 側 PowerShell / Codex を使う必要があれば、`docs/TOOL_PLAYBOOK.md` を見て `scripts/win_pwsh.sh` / `scripts/win_codex.sh` を優先する。
- `GEMINI.md`、`.gemini/commands/`、`.gemini/agents/`、`.agents/skills/` を更新したあとは、必要なら reload を使う。
- `GEMINI.md` を分割したいときは `@path/to/file.md` import を使い、`/memory show` で実際の読込内容を確認する。
- session の context が重いと感じたら、可能なら `/stats` で確認する。
