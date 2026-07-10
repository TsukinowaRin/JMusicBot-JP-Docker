# ハーネス構成ガイド

このファイルは、このテンプレートが 6 CLI（Claude Code / Codex / Antigravity CLI / Cursor / opencode / Kilo Code）でどう動くかの正本。CLI 差分、skills、hooks、wrapper、検証はここだけ見れば分かる状態を保つ。

## 設計原則

1. **native-first / 同期より参照**: 各 CLI が native に読める場所（`AGENTS.md`、`.agents/skills/`）を最大限使い、生成 mirror は最小にする。
2. **always-on context 最小化**: 常時読まれるのは `AGENTS.md`（+ Claude は `CLAUDE.md`）だけ。長い知識は skills（必要時 lazy 読込）と docs へ逃がす。
3. **deterministic gate**: prompt だけで防げない失敗は hooks / permissions / smoke script で機械的に止める。
4. **docs = working memory**: chat 履歴なしで `docs/` だけから再開できる状態を保つ。

## CLI 対応マトリクス（2026-07 検証、出典は docs/SOURCES.md）

| CLI | always-on rules | skills | guard |
|---|---|---|---|
| Claude Code | `CLAUDE.md`（`@AGENTS.md` import。AGENTS.md native 非対応） | `.claude/skills/`（生成 mirror） | `.claude/settings.json` + `.claude/hooks/` |
| Codex | `AGENTS.md` native | `.agents/skills/` native | `.codex/config.toml` `[hooks]` + `.codex/hooks/` |
| Antigravity (agy) | `AGENTS.md` native | `.agents/skills/` native | `.agents/hooks.json` + `.agents/hooks/` |
| Cursor | `AGENTS.md` native | `.agents/skills/` native | `.cursor/hooks.json` + `.cursor/hooks/` |
| opencode | `AGENTS.md` native | `.agents/skills/` native | `opencode.jsonc` `permission` |
| Kilo Code | `AGENTS.md` native | `.agents/skills/` native | `kilo.jsonc` `permission` + `skills.paths` |

## Skills

- 編集元は `.agents/skills/` のみ。1 ディレクトリ 1 skill、ルートに `SKILL.md`、frontmatter は `name`（ディレクトリ名と一致、`^[a-z0-9]+(-[a-z0-9]+)*$`、1-64 chars）と `description`（1-1024 chars、trigger words を前半に）。
- `.claude/skills/` は唯一の mirror。`python3 scripts/sync_shared_skills.py` で同期し、手で編集しない。差分は smoke が検出する。
- 標準 skill 構成:
  - `start-task`: タスク開始時の文脈 triage（small / medium / deep）
  - `execplan`: 複雑作業の REQS 正規化と実行計画
  - `checkpoint`: commit / 中断 / handoff 前の検証・docs 同期・停止点記録
  - `karpathy-guidelines`: 実装品質の4原則ガード
  - `security-harness`: secrets / admin / prompt injection / release の確認
  - `harness-loop`: 長時間・複数エージェント作業の loop 設計
  - `human-readable-writing`: 人間向け日本語の anti-slop
  - `design-taste-frontend`: frontend の anti-slop（`DESIGN.md` とセット）
  - `local-skill-bootstrap`: 足りない workflow を repo local skill として新設
- 新しい workflow が繰り返し必要になったら、外部 download より `local-skill-bootstrap` で local 作成する。

## Hooks / Permissions

- 共通ロジックは `.agent-shared/hooks_core/`（危険コマンド、admin escalation、secret path、skill への外部 download を deny）。各 CLI の adapter は payload / 出力 schema の変換だけを行う。
- Claude Code: `.claude/settings.json` の `SessionStart`（bootstrap context 注入）と `PreToolUse`（Bash / Edit / Write を policy 検査）。
- Codex: `.codex/config.toml` の `[features].hooks = true` + inline `[hooks]`。project-local hooks は初回に `/hooks` で承認が要る場合がある（設定エラーではない）。
- Antigravity: `.agents/hooks.json` の `PreInvocation`（`injectSteps[].ephemeralMessage`）と `PreToolUse`（`decision: deny`）。
- Cursor: `.cursor/hooks.json` の `beforeShellExecution` / `beforeReadFile`。拒否は `{"permission": "deny"}` を返す。
- opencode / Kilo Code: hook 機構の代わりに `opencode.jsonc` / `kilo.jsonc` の `permission` セクションで deny / ask を宣言する。
- 共通ポリシー: secret ファイル（`.env`、`.pem`、`.p12`、`id_rsa`、`aws/credentials` など）は deny（`.env.example` 等は allow）。破壊的コマンド（`git reset --hard`、`git clean -fd`、`rm -rf /`、`mkfs`、`dd`）は deny。`git push` と外部 download（`curl`、`wget`、`git clone`）は ask。admin 昇格は `AGENT_ADMIN_APPROVED=1` 付きの明示承認時のみ。

## Subagents

- Claude Code: `.claude/agents/`（code-reviewer / docs-maintainer / test-debugger）。
- Antigravity: native の `/agents` パネルと dynamic subagents。
- Kilo Code: `.kilo/agents/`、opencode: `.opencode/agents/`（docs / review / test の軽量 subagent。権限は最小化済み）。
- Cursor / Codex: native の subagent / 並列機能を使う。repo 固有の役割定義が要る場合だけ設定を足す。

## 自己ループ runner（agent_loop）

- `scripts/agent_loop.py` は、headless CLI を goal 達成まで自動で再起動する loop 実行機構。1 起動 = 1 chunk しか進まない CLI に対して人間が「続けて」を打つ作業を代行する。
- loop の定義は `.agent-shared/loops/` の profile（markdown + 簡易 frontmatter）。同梱 profile:
  - `security-review.md`: `SECURITY.md` + security-harness skill 観点の監査 → 重大度順修正の反復。gates は security_smoke など。
  - `design-review.md`: `DESIGN.md` + design-taste-frontend skill 観点の UI 点検 → 改善の反復。gates は対象プロジェクトの lint / build に差し替えて使う。
  - `TEMPLATE.md`: 任意タスク用 scaffold。gates（機械実行できる完了判定）は必須で、空にできない。
- 実行例: `python3 scripts/agent_loop.py --profile .agent-shared/loops/security-review.md --cli codex`（preset: claude / codex / agy / opencode / kilo / cursor。`--agent-cmd` で自由指定、`--dry-run` で構成検証のみ）。
- 仕組み: 毎 iteration fresh context で CLI を headless 起動し、エージェントに docs/WORKLOG.md の更新と `LOOP_STATUS: CONTINUE|DONE|BLOCKED` の宣言をさせる。DONE は gates 全 pass の時だけ受理。停止条件は DONE+gates（exit 0）/ BLOCKED（2）/ workspace 無変化 stall（3）/ 契約行連続欠落（4）/ max_iterations（5）。
- state はエージェントが docs に書く（docs = working memory 原則）。runner 自身は `.loop/`（gitignore 済み）に prompt / 出力ログを残すだけなので、中断後も同じコマンドの再実行で docs から続きになる。
- 安全策: 各 CLI の hooks / permission deny が効いたままの auto-approve 水準（例: claude は `--permission-mode acceptEdits`、codex は `exec --full-auto`）だけを使い、runner は push / merge を行わない。詳細は harness-loop skill。

## CLI 別の運用メモ

- **Antigravity CLI**: terminal-first の実体は `agy`（`antigravity` は GUI launcher の場合があるため headless smoke に使わない）。実機確認は `agy --version`、認証済みなら `agy --add-dir "$PWD" -p "Return exactly OK"`。timeout 時は失敗と決めず `--continue` で継続する。user-level 設定 `~/.gemini/antigravity-cli/settings.json` はテンプレートから書き換えない。
- **Codex**: `AGENTS.md` は global → project root → 作業ディレクトリの順に読まれ、近いものが後勝ち。project docs は約 32KiB 上限があるため always-on を短く保つ。
- **Cursor**: rules は skills へ移行が進んでいるため、`.cursor/rules/` は使わず `AGENTS.md` + `.agents/skills/` に寄せる。CLI の実体は `cursor-agent`（`agent` alias）。headless は `cursor-agent -p` で、未 trust のディレクトリでは `--trust` が必要。hook block 時は「Rejected: Command execution was blocked by a hook.」が返る。
- **opencode / Kilo Code**: project config は `opencode.jsonc` / `kilo.jsonc`。instruction ファイルの指定は不要（`AGENTS.md` を native 検出）。
- 全 CLI 共通: project-level で model を pin しない。必要時だけ `/model` / `--model` / user config で切り替える。

## Windows / WSL wrapper

- WSL → Windows PowerShell: `scripts/win_pwsh.sh`（inline と `--file <path.ps1>` の両対応。pwsh.exe 優先、無ければ powershell.exe）。
- WSL → Windows 側 Codex: `scripts/win_codex.sh`（`cmd.exe /c codex.cmd` の直書きは PATH 解決が不安定なので禁止。実体指定は `WIN_CODEX_CMD=...`）。
- Windows → WSL: `scripts/wsl_exec.ps1` / `scripts/wsl_exec.cmd`（`-Workdir` は WSL / Windows 両 path 対応、複数コマンドは `-ShellCommand`）。
- 管理者権限（UAC / sudo）が要る操作は wrapper に混ぜず、目的・変更対象・rollback・検証方法を説明し、ユーザーが直前に OK した1コマンドだけ `AGENT_ADMIN_APPROVED=1` を付けて実行する。

## 検証

- 構造 smoke: `bash scripts/smoke_template.sh`（必須ファイル、廃止ファイル不在、stale 参照、skill metadata、mirror 一致、hooks 構文、policy 動作）。Windows wrapper 部分は `TEMPLATE_SMOKE_WINDOWS=0` で skip、`TEMPLATE_SMOKE_WINDOWS_TIMEOUT=20s` で調整。
- 安全策 smoke: `bash scripts/security_smoke.sh`。
- loop profile の構成検証: `python3 scripts/agent_loop.py --profile <p> --dry-run`。
- skill 追加・変更後は `python3 scripts/sync_shared_skills.py` → smoke の順で確認する。

## テンプレート導入手順

1. root 一式を対象 repo のワークスペース表層へコピーする（`Old/` と `.git/` は除く）。
2. `docs/PROJECT_BRIEF.md` をその repo の build / test / run / 制約で埋める。
3. `docs/REQS.md` / `docs/WORKLOG.md` を空 scaffold に戻し、最初のタスクで埋める。
4. `README.md` はプロジェクト本体の README に置き換えてよい（ハーネスの説明はこのファイルが正本）。
5. `bash scripts/smoke_template.sh` で構造が壊れていないことを確認する。
