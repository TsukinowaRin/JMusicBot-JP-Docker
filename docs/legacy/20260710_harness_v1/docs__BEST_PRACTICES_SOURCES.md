# 公式ソースと設計メモ

このテンプレートは、2026-04-21 時点の公式ソースをもとに設計した。二次情報ではなく、各ベンダー自身の docs / repo / help center を優先している。

## Claude Code

- [How Claude remembers your project](https://code.claude.com/docs/en/memory)
  - `CLAUDE.md` は毎回読まれる persistent instructions。
  - project instructions は `./CLAUDE.md` または `./.claude/CLAUDE.md`。
  - 長くしすぎず、具体的・簡潔に書く。目安は 200 行未満。
  - 多段手順や一部のコードパスだけに効くルールは skills や path-scoped rules に分ける。
  - `AGENTS.md` を既に使っている repo では、`CLAUDE.md` から `@AGENTS.md` import するのが公式推奨。
- [Hooks reference](https://code.claude.com/docs/en/hooks)
  - `PreToolUse` / `PostToolUse` / `SessionStart` などで tool call を制御できる。
  - project-level hooks は `.claude/settings.json` で構成する。
- [Create custom subagents](https://code.claude.com/docs/en/sub-agents)
  - subagent は独立した context window と権限を持つ。調査や review の分離に向く。
- [Claude Code settings](https://code.claude.com/docs/en/settings)
  - 共有設定は `.claude/settings.json`、個人設定は `.claude/settings.local.json`。
- [Security](https://code.claude.com/docs/en/security)
  - read-only permissions が既定で、追加操作には明示 permission を使う。

## Gemini CLI

- [Provide context with GEMINI.md files](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md)
  - `GEMINI.md` は階層的に読み込まれる project context file。
  - `@path.md` import と `/memory show` / `/memory reload` が使える。
  - `context.fileName` で `AGENTS.md` を併読対象にできる。
- [Gemini CLI configuration](https://github.com/google-gemini/gemini-cli/blob/main/docs/reference/configuration.md)
  - config は user / project / env / CLI flags の precedence を持つ。
  - context files は hierarchy で管理し、より具体的なものが補足・上書きしやすい。
- [Custom commands](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/custom-commands.md)
  - project commands は `.gemini/commands/` に置く。
  - 更新後は `/commands reload` を使える。
- [CLI commands](https://github.com/google-gemini/gemini-cli/blob/main/docs/reference/commands.md)
  - `/skills reload`、`/agents reload`、`/memory refresh`、`/plan`、`/resume` が available。
- [Sandboxing](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/sandbox.md)
  - 最小権限の sandbox profile を使うのが推奨。
- [Plan Mode](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/plan-mode.md)
  - Plan Mode は read-only を前提にした planning 環境。

## Codex

- [CLI – Codex](https://developers.openai.com/codex/cli)
  - Codex CLI は local coding agent。
  - Windows は WSL2 が推奨。
- [Best practices – Codex](https://developers.openai.com/codex/learn/best-practices)
  - `AGENTS.md` には repo layout、run/build/test/lint、conventions、constraints、done / verify を書くとよい。
  - `/init` は starter `AGENTS.md` を作るが、実運用に合わせて編集が必要。
- [Custom instructions with AGENTS.md](https://developers.openai.com/codex/guides/agents-md)
  - `AGENTS.md` は Codex の project instructions の中心になる。
- [Config basics](https://developers.openai.com/codex/config-basic)
  - user config は `~/.codex/config.toml`、project config は `.codex/config.toml`。
  - trusted project でのみ project config を読む。
- [Agent approvals & security](https://developers.openai.com/codex/agent-approvals-security)
  - `workspace-write` + `on-request` などの approval / sandbox presets がある。
  - `--full-auto` は `workspace-write` + `on-request` の alias。
- [Hooks](https://developers.openai.com/codex/hooks)
  - `SessionStart`、`PreToolUse`、`PostToolUse` を config で構成できる。
- [Skills](https://developers.openai.com/codex/skills)
  - skills は reusable workflow の authoring format。
  - `SKILL.md` と optional scripts / references を持てる。
- [Memories](https://developers.openai.com/codex/memories)
  - memories は generated state として扱い、手編集を primary control surface にしない。

## このテンプレートへの反映

- `AGENTS.md` を共通ルールの中心にした。
- Claude だけ `AGENTS.md` を直接読まないため、`CLAUDE.md` で import する。
- Gemini は `.gemini/settings.json` の `context.fileName` に `AGENTS.md` と `GEMINI.md` を入れる。
- Codex / Claude / Gemini で共通化しづらい差分は hooks / commands / agents の adapter に分離した。
- docs は `PROJECT_BRIEF` / `REQS` / `EXECPLAN` / `WORKLOG` で current task を追跡できる構成にした。
