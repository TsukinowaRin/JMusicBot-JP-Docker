# 公式ソースと設計メモ

このテンプレートは、2026-07-04 時点の公式ソースをもとに設計する。二次情報ではなく、各ベンダー自身の docs / blog と repository README / code を優先する。旧版の出典（2026-06-20 検証）は `Old/docs/BEST_PRACTICES_SOURCES.md` に残っている。

## AGENTS.md 標準

- [agents.md](https://agents.md/)
  - AGENTS.md は Sourcegraph / OpenAI / Google / Cursor / Factory 発の共通 instruction 標準で、Linux Foundation 管理。Codex / Antigravity / Cursor / opencode / Kilo Code が native に読む。
- [anthropics/claude-code issue #6235](https://github.com/anthropics/claude-code/issues/6235)
  - Claude Code は 2026-07 時点で AGENTS.md を native に読まない。`CLAUDE.md` に `@AGENTS.md` import を置く方式が公式にサポートされた橋渡しで、このテンプレートもそれを採る。

## Claude Code

- [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices)
  - context window は最重要リソース。探索、計画、実装を分け、subagents で調査を分離する。
- [Extend Claude Code](https://code.claude.com/docs/en/features-overview)
  - `CLAUDE.md` は always-on、Skills は on-demand、Hooks は guardrail。`CLAUDE.md` は 200 行未満を目安にする。
- [Hooks reference](https://code.claude.com/docs/en/hooks)
  - project-level hooks は `.claude/settings.json`。`SessionStart` / `PreToolUse` を使う。
- [Claude Code Skills](https://code.claude.com/docs/en/skills)
  - skill の name は常時読まれ、description は数が多いと短縮されうる。trigger words を description 前半に置く。

## Codex / GPT-5.5

- [Custom instructions with AGENTS.md](https://developers.openai.com/codex/guides/agents-md)
  - global → project root → 作業ディレクトリの順に読み、近いものが後勝ち。project docs は約 32KiB 上限。
- [Agent Skills – Codex](https://developers.openai.com/codex/skills)
  - skills は progressive disclosure。repo-local skills は `.agents/skills/` に置ける。
- [Hooks – Codex](https://developers.openai.com/codex/hooks) / [Config basics](https://developers.openai.com/codex/config-basic)
  - project config は `.codex/config.toml`。`[features].hooks = true` で有効化し、deny は `hookSpecificOutput.permissionDecision = "deny"`。

## Antigravity CLI

- [Transitioning Gemini CLI to Antigravity CLI](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/)
  - 2026-05-19 告知。Agent Skills / Hooks / Subagents / plugins を引き継ぐ。旧 `.gemini/` 構造は持ち込まない。
- [Antigravity CLI features](https://antigravity.google/docs/cli-features) / [hooks](https://www.antigravity.google/docs/hooks)
  - workspace customization は `.agents/`。AGENTS.md を project instruction として native に読む。hooks は `.agents/hooks.json`（`PreInvocation` は `injectSteps[].ephemeralMessage`、`PreToolUse` は `decision: allow|deny|ask`）。
- local observation
  - terminal-first binary は `agy`。`antigravity` は GUI launcher の場合があるため headless smoke には `agy -p` を使う。

## Cursor（2026-07-04 追加検証）

- [Agent Skills | Cursor Docs](https://cursor.com/docs/context/skills)
  - Cursor は `.agents/skills/` と `.cursor/skills/` から skill を native 読込し、互換として `.claude/skills/` / `.codex/skills/` も読む。SKILL.md frontmatter は `name` / `description`（+ optional `paths`, `disable-model-invocation`）。rules は `/migrate-to-skills` で skills への移行が推奨方向。
- [Hooks | Cursor Docs](https://cursor.com/docs/agent/hooks)
  - project-level は `.cursor/hooks.json`（`{"version": 1, "hooks": {...}}`）。event は `beforeShellExecution` / `beforeReadFile` / `preToolUse` など。拒否は exit code 2 または `{"permission": "deny"}` JSON。
- [Best practices for coding with agents](https://cursor.com/blog/agent-best-practices)
  - AGENTS.md を project root（と subdirectory）で読む。

## Kilo Code

- [Custom Instructions](https://kilo.ai/docs/customize/custom-instructions) / [Skills](https://kilo.ai/docs/customize/skills)
  - `AGENTS.md` を自動検出し primary instruction にできる。project skills は `.kilo/skills/` に加え `.claude/skills/` / `.agents/skills/` も読む。
- [Custom Modes](https://kilo.ai/docs/customize/custom-modes)
  - agent は `.kilo/agents/*.md` か `kilo.jsonc` の `agent` key で定義し、`permission` で絞れる。

## opencode

- [Rules](https://opencode.ai/docs/rules) / [Agent Skills](https://opencode.ai/docs/skills/)
  - project rules は `AGENTS.md`。skills は `.opencode/skills/` / `.claude/skills/` / `.agents/skills/` を検出。`name` はディレクトリ名一致、`description` は 1-1024 chars。
- [Config](https://opencode.ai/docs/config/) / [Permissions](https://opencode.ai/docs/permissions/)
  - project config は `opencode.jsonc`。`permission` で `bash` / `edit` / `read` などを allow / ask / deny にできる。

## Harness / Loop / 品質

- [SWE-agent/mini-swe-agent](https://github.com/SWE-agent/mini-swe-agent)
  - 小さい harness と評価可能な task ほど再現性が上がる。巨大 framework ではなく最小 wrapper と smoke を優先する。
- [jpicklyk/task-orchestrator](https://github.com/jpicklyk/task-orchestrator) / [cobusgreyling/loop-engineering](https://github.com/cobusgreyling/loop-engineering)
  - workflow は prompt でなく deterministic gate（hooks / permissions / smoke / acceptance criteria）で守る。loop は state / budget / stop 条件を持つ system として設計する（`.agents/skills/harness-loop/`）。
- [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills)
  - 4原則（Think Before Coding / Simplicity First / Surgical Changes / Goal-Driven Execution）を `AGENTS.md` と `karpathy-guidelines` skill に再構成。

## Design / Writing / Security

- [VoltAgent/awesome-design-md](https://github.com/VoltAgent/awesome-design-md) / [kzhrknt/awesome-design-md-jp](https://github.com/kzhrknt/awesome-design-md-jp) / [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill)
  - `DESIGN.md` を plain-text design system として扱う構成と、anti-slop frontend の考え方（`design-taste-frontend` skill）。
- [iKora128/stop-ai-slop-jp](https://github.com/iKora128/stop-ai-slop-jp)
  - 日本語の AI 臭さを主体の不在・反証不能な抽象・均一リズムとして扱う（`human-readable-writing` skill）。
- [OWASP Top 10 for LLM Applications](https://owasp.org/www-project-top-10-for-large-language-model-applications/) / [GitHub Docs: security policy](https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository)
  - prompt injection / excessive agency / supply chain を主要脅威とし、`SECURITY.md`、`security-harness` skill、hooks、`scripts/security_smoke.sh` に分解。

## 実機検証（2026-07-06、WSL2 + テンプレをコピーした新規ワークスペースで実測）

`tmp/testws-20260706` にテンプレートを配布形（Old/ と .git なし）でコピーし、git init 後に headless session で確認した。

| CLI | AGENTS.md 読込 | skills 認識 | guard 発火 |
|---|---|---|---|
| Claude Code | ✅ `@AGENTS.md` import 経由（見出し引用で確認） | ✅ `.claude/skills/` 9本 | ✅ SessionStart / PreToolUse とも実 session で発火確認 |
| Codex 0.142 | ✅ 見出し引用で確認 | ✅ `.agents/skills/` 9本 | instruction 層で拒否を確認（AGENTS.md の安全策を引用して実行拒否）。hook 機構は `~/.codex/config.toml` の `hooks.state` に他 project の `.codex/config.toml` 承認記録があり project hooks 対応を確認。初回 interactive 承認が必要 |
| Antigravity 1.0.13 | ✅ 見出し引用で確認 | ✅ `.agents/skills/` 9本 | ✅ `cat .env` probe が hooks_core の deny 文言原文でブロックされた |
| opencode | ✅ 見出し引用で確認 | ✅ `.agents/skills/` 9本 | ✅ `.env` read が `opencode.jsonc` の deny ルールでブロックされた（user global の ask より project deny が優先） |
| Kilo Code | ✅ 見出し引用で確認（free モデル `kilo/kilo-auto/free`、認証不要で実行可） | ✅ `kilo debug skill` と実 session の両方で 9本（`.agents/skills/` と `.claude/skills/` の両方から解決） | ✅ `.env` read が `kilo.jsonc` の deny ルールでブロックされた（既定モデルは PAID_MODEL_AUTH_REQUIRED で不可のため free モデル指定で検証） |
| Cursor CLI 2026.07.01 | ✅ 見出し引用で確認（headless は `--trust` が必要） | ✅ `.agents/skills/` 9本を過不足なく列挙 | ✅ `cat .env` probe が `.cursor/hooks.json` の hook でブロックされた（「Rejected: Command execution was blocked by a hook.」）。payload key の懸念は解消 |

- 補足: `.env` probe は Claude Code headless では API 安全層に flag され実行不能だったため、Claude Code の hook 発火は実作業 session での観測（SessionStart 注入、`sudo` リテラル入りコマンドの PreToolUse deny）を根拠とする。

## v2 での主な設計反映（2026-07-04）

- mirror は `.claude/skills/` のみ。Codex / Antigravity / Cursor / opencode / Kilo は `.agents/skills/` native 読込のため、旧 `.codex/skills/` / `.kilo/skills/` / `.opencode/skills/` mirror を廃止。
- bridge memory は `CLAUDE.md` のみ。旧 `ANTIGRAVITY.md` / `KILO.md` / `OPENCODE.md` は AGENTS.md native 読込のため廃止。
- docs は PROJECT_BRIEF / REQS / WORKLOG / HARNESS の4本コア + SOURCES + EXECPLAN に統合。
- Cursor guard を `.cursor/hooks.json` + 共通 hooks_core の thin adapter として新設。
