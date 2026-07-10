# 互換性ガイド

このテンプレートでは、Claude Code / Codex / Gemini CLI の互換性を「共通化できるところは共通化し、無理な差分は adapter で吸収する」方針で高める。

## Skills

- 採用する共通 subset
  - ディレクトリごとに 1 skill
  - ルートに `SKILL.md`
  - frontmatter は原則 `name` と `description` のみ
  - 本文は Markdown instructions
  - 必要なら `scripts/`, `references/`, `assets/` を追加
- 配置
  - 共通 canonical source は `.agents/skills/`
  - `Codex` と `Gemini CLI` は `.agents/skills/` を使う
  - `Claude Code` は `.claude/skills/` を使うが、内容は `.agents/skills/` と同じ subset にそろえる
  - 差分を防ぎたい場合は `scripts/sync_shared_skills_to_claude.py` で skill directory 全体を同期する
  - shared skill の新規作成には `.agents/skills/local-skill-bootstrap/` を使う

## Commands / reusable workflows

- 完全共通の command 規格は無い
- このテンプレートでの扱い
  - `Codex`: workflow の意図は `.agents/skills/` で表現する
  - `Claude Code`: `.claude/commands/` に command を置く
  - `Gemini CLI`: `.gemini/commands/` に command を置く
- 共通化の考え方
  - 「いつ使うか」と「何を達成するか」はそろえる
  - frontmatter や記法は各 CLI の流儀に合わせる
  - まず `context-triage`, `bootstrap-fast`, `checkpoint-pack` のような短い再利用導線から揃える

## モデル既定値の方針

- この template では、Codex / Claude Code / Gemini CLI の project-level 既定 model は pin しない
- 既定値は各 CLI の default / Auto / alias 解決に任せる
- 理由:
  - 普段使いで設定保守を軽くするため
  - provider 側の安定版更新に追従しやすくするため
  - pin が必要なのは benchmark、障害切り分け、handoff 再現のときに限るため
- 手動 override の考え方
  - Codex: CLI 側の model 指定や user 設定で切り替える
  - Claude Code: `/model`、`--model`、settings の `model`
  - Gemini CLI: `--model`、`GEMINI_MODEL`、settings の `model.name`

## Gemini CLI の memory 方針

- Gemini CLI は project memory と大きい context window を持てるが、この template では「読めるから全部読む」運用をしない
- `.gemini/settings.json` の `context.fileName` は `AGENTS.md` と `GEMINI.md` だけに絞る
- Claude 固有の memory file は Gemini の自動読込対象に入れない
- docs の広い読込みは fast path / deep path と `context-audit` で制御する
- session が重いときは `/stats` と reload 系コマンドを使って文脈を整える
- effective model が想定と違うときは `/about` で確認し、必要時だけ `--model ...` や `GEMINI_MODEL=...` で override を切り分ける

## Hooks

- 3製品で完全共通の hook 規格は無い
- 差が大きいのは event 名、matcher、deny/allow の出力フィールド
- このテンプレートでの扱い
  - 共通ロジックは `.agent-shared/hooks_core/` に置く
  - CLI ごとの hook script は薄い adapter にする
  - `Codex`: `.codex/hooks/`
  - `Claude Code`: `.claude/hooks/`
  - `Gemini CLI`: `.gemini/hooks/`
- 互換性の考え方
  - ルールの本体は 1 か所に集約する
  - CLI 固有の schema 変換だけを adapter で吸収する
  - 新しい CLI を追加するときも、adapter だけ足せばよい構成にする
  - shared skill directory への外部ダウンロードは共通 hook で抑止し、local skill 作成へ寄せる

## どこまで共通化しないか

- `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` の読まれ方は完全には同じではない
- subagents / custom agents の frontmatter も各製品で差がある
- そのため、memory files と agent definitions は「意味をそろえる」が、「完全な 1 ファイル共通」にはしない

## Windows wrapper の共通入口

- WSL から Windows 側 PowerShell を叩く入口は `scripts/win_pwsh.sh` に統一する
- `.ps1` も別 wrapper を作らず `scripts/win_pwsh.sh --file ...` で実行する
- Windows 側 `codex` は `scripts/win_codex.sh` を使う
- Windows から WSL を叩く入口は `scripts/wsl_exec.ps1` と `scripts/wsl_exec.cmd` にそろえる
- 通常運用では Windows OpenSSH を前提にせず、wrapper の direct / `cmd.exe` 経路を標準とする
- これにより、Codex / Claude Code / Gemini CLI のどれでも同じコマンド例を docs に載せられる
