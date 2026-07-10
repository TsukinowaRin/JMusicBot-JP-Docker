# Core Rules

- `AGENTS.md` と `docs/` を source of truth とする。
- CLI 差分とハーネス構成の正本は `docs/HARNESS.md` を読む。
- Gemini CLI 互換の `.gemini/` は使わない。Agy では `.agents/skills/`、`.agents/hooks.json`、`.agents/plugins/`、`/agents`、`/permissions`、`/model` を使う。
- terminal-first CLI は `agy`。`antigravity` は GUI / VS Code 系 launcher の場合があるため、headless smoke には使わない。
- project-level model は pin しない。通常は Agy の Auto / default に任せ、必要なときだけ `/model` か user-level settings で切り替える。
