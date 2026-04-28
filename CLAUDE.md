@AGENTS.md
@docs/AGENT_BOOTSTRAP.md

# Claude Code 向け補足

- このファイルは短く保つ。話題別の詳細ルールは `.claude/rules/` に置く。
- `CLAUDE.md` は毎回読まれる前提なので、長文化したら import や `.claude/rules/` に分割する。
- 回答、説明、レビュー、作業ログは原則日本語で行う。ユーザーが明示的に他言語を指定した場合のみ切り替える。
- 途中経過の逐次報告は避け、必要な報告はチェックポイントに絞る。
- 繰り返し使うワークフローには `.claude/skills/` を使う。
- fast bootstrap と checkpoint 整理には `.claude/commands/` を優先して使う。
- project-level では model を pin しない。Claude Code の default / alias を使い、比較検証や障害切り分けのときだけ `/model` や `--model` で切り替える。
- 分離や専門化が有効な作業では `.claude/agents/` の subagent を使う。
- project hooks を尊重し、ブロックされた操作を別の危険な書き方で回避しない。
- WSL から Windows 側 PowerShell / Codex を使う必要があれば、`docs/TOOL_PLAYBOOK.md` を見て `scripts/win_pwsh.sh` / `scripts/win_codex.sh` を優先する。
