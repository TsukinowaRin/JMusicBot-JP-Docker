# ハーネス構成ガイド

このファイルは、このテンプレートが 7 CLI（Claude Code / Codex / Antigravity CLI / Cursor / opencode / Kilo Code / Grok CLI）でどう動くかの正本。CLI 差分、skills、hooks、wrapper、検証はここだけ見れば分かる状態を保つ。

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
| Grok CLI (xAI) | `AGENTS.md` native（`CLAUDE.md`も検出） | project skillsを自動検出（`grok inspect`で確認） | `.grok/config.toml` native permission + trust後のClaude互換hook（camelCase対応済み） |

## Skills

- 編集元は `.agents/skills/` のみ。1 ディレクトリ 1 skill、ルートに `SKILL.md`、frontmatter は `name`（ディレクトリ名と一致、`^[a-z0-9]+(-[a-z0-9]+)*$`、1-64 chars）と `description`（1-1024 chars、trigger words を前半に）。
- `.claude/skills/` は唯一の mirror。`python3 scripts/sync_shared_skills.py` で同期し、手で編集しない。差分は smoke が検出する。
- 標準 skill 構成:
  - `start-task`: タスク開始時の文脈 triage（small / medium / deep）
  - `execplan`: 複雑作業の REQS 正規化と実行計画
  - `checkpoint`: commit / 中断 / handoff 前の検証・docs 同期・停止点記録
  - `security-harness`: secrets / admin / prompt injection / release の確認
  - `harness-loop`: 長時間・複数エージェント作業の loop 設計
  - `human-readable-writing`: 人間向け日本語の anti-slop
  - `design-taste-frontend`: frontend の anti-slop（`DESIGN.md` とセット）
  - `local-skill-bootstrap`: 足りない workflow を repo local skill として新設
  - `codebase-improvement-audit`: source を変更しない横断監査 → 根拠の再確認 → 別エージェント向け ExecPlan の作成
- 新しい workflow が繰り返し必要になったら、外部 download より `local-skill-bootstrap` で local 作成する。

## Hooks / Permissions

- 共通ロジックは `.agent-shared/hooks_core/`（危険コマンド、admin escalation、secret path、skill への外部 download を deny）。各 CLI の adapter は payload / 出力 schema の変換だけを行う。
- Claude Code: 静的contextは`CLAUDE.md`から読み、`.claude/settings.json`の`PreToolUse`（Bash / Edit / Write）でpolicyを検査する。
- Codex: `.codex/config.toml` の `[features].hooks = true` + inline `[hooks]`。project-local hooks は初回に `/hooks` で承認が要る場合がある（設定エラーではない）。
- Antigravity: 静的contextは`AGENTS.md`から読み、`.agents/hooks.json`の`PreToolUse`（`decision: deny`）でpolicyを検査する。
- Cursor: `.cursor/hooks.json` の `beforeShellExecution` / `beforeReadFile`。拒否は `{"permission": "deny"}` を返す。
- opencode / Kilo Code: hook 機構の代わりに `opencode.jsonc` / `kilo.jsonc` の `permission` セクションで deny / ask を宣言する。
- Grok: `.grok/config.toml`はfolder trust前にも読み込まれ、secret / 破壊操作をdeny、admin / push / downloadをaskにする。trust後は`.claude/settings.json`のproject hookも発火し、adapterが`toolName` / `toolInput`と`run_terminal_command` / `read_file` / edit aliasをshared policyへ変換する。Grok denyは`{"decision":"deny","reason":"..."}` + exit 2。
- 共通ポリシー: secret ファイル（`.env`、`.pem`、`.p12`、`id_rsa`、`aws/credentials` など）は deny（`.env.example` 等は allow）。破壊的コマンド（`git reset --hard`、`git clean -fd`、`rm -rf /`、`mkfs`、`dd`）は deny。`git push` と外部 download（`curl`、`wget`、`git clone`）は ask。admin 昇格は `AGENT_ADMIN_APPROVED=1` 付きの明示承認時のみ。

## Subagents

native subagentは、通常利用でもモデル判断だけでは起動させない。CLIごとの境界は次のとおり。

| CLI | 通常利用 | mailbox / agent_loop | 再委任 |
|---|---|---|---|
| Claude Code | `.claude/settings.json`で`Agent`をask | `--disallowedTools Agent` | `.claude/agents/*.md`で`disallowedTools: Agent` |
| Codex | `.codex/config.toml`で`multi_agent = false` | `--disable multi_agent` | spawn機能自体を提供しない |
| Antigravity | hookが`invoke_subagent` / `define_subagent`を`force_ask` | `HARNESS_UNATTENDED=1`時はdeny | 同じhookを継承 |
| Cursor | `subagentStart` hookでdeny | 同じhookでdeny | 全階層の開始eventをdeny |
| OpenCode / Kilo | global `task: ask` | primary `mailbox-worker`の`task: deny` | repo-local agentも`task: deny` |
| Grok | `.grok/config.toml`で`Agent`をask | `--no-subagents` | 起動ごとのaskを継承 |

Cursorの`subagentStart`は`ask`をサポートせず、値を指定してもdenyとして扱う。そのためCursorだけは通常利用も全面deny。Codexでnative subagentを意図的に使う場合は、利用者が実行単位で`--enable multi_agent`を付ける。CLI横断の役割分担はnative subagentではなく、下記mailboxを使う。

### Mailboxで待つ

`scripts/agent_mailbox.py`は、CLIをまたぐ下請け通信を`.loop/mailboxes/`で扱う。10分ごとに
確認するのはPython dispatcherだけで、空mailboxではAI CLIを起動しない。複数messageは1回の
batchにまとめる。

    下請けがMarkdownを投函 -> 10分gateまでmodelは停止
      -> dispatcherが宛先を検証 -> messageありの時だけ受信agentを1回起動

配送先は3値で固定する。

- `role`: `worker1`のような窓口名。同時にactiveなinstanceは1つだけ。
- `instance`: agentを登録するたびに変わる世代ID。roleを再利用しても旧messageを混ぜない。
- `task_id`: そのmessageが属する仕事。受信instanceのtaskと完全一致しないmessageは配送しない。

最小手順。全agentを同じtaskへ登録し、返された`instance`を各プロセスが保持する。

```bash
python3 scripts/agent_mailbox.py register --role supervisor --task TASK-001 --interval 600
python3 scripts/agent_mailbox.py register --role worker1 --task TASK-001 --interval 600

python3 scripts/agent_mailbox.py send \
  --from-instance <worker1-instance> --to-role supervisor --task TASK-001 \
  --type done --body "実装完了。結果はdocs/WORKLOG.mdを参照。"

python3 scripts/agent_mailbox.py deliver \
  --instance <supervisor-instance> --wait \
  --agent-cmd "codex exec --full-auto --skip-git-repo-check"
```

`deliver --wait`は次の確認時刻まで1回だけsleepして終了する。定期運用はOS schedulerなどから
このone-shot commandを10分ごとに呼ぶ。dispatcherはsystem schedulerを勝手に登録・変更しない。
Claude Codeのようにpromptをstdinで受けるcommandには`--prompt-stdin`を付ける。

opencodeでread-only review workerを直接起動する場合は、次のcommandを使う。

```bash
python3 scripts/agent_mailbox.py deliver \
  --instance <reviewer-instance> \
  --agent-cmd "opencode run --dir <workspaceの絶対path> --agent repo-reviewer"
```

`repo-reviewer`は`mode: all`なので、通常sessionからsubagentとして呼ぶ用途も維持する。これを
`mode: subagent`へ戻すと、`opencode run --agent repo-reviewer`はwarningを出して編集可能なdefault
`build` agentへfallbackする。

編集を行うOpenCode / Kilo Workerは、再委任禁止の専用primaryを使う。

```bash
python3 scripts/agent_mailbox.py deliver \
  --instance <worker-instance> \
  --agent-cmd "opencode run --dir <workspaceの絶対path> --agent mailbox-worker"

python3 scripts/agent_mailbox.py deliver \
  --instance <worker-instance> \
  --agent-cmd "kilo run --dir <workspaceの絶対path> --agent mailbox-worker"
```

`mailbox-worker`は`task: deny`と`doom_loop: deny`を持つ。OpenCode / KiloのTask toolからsubagentが除外され、
CLI内部の自動回復loopも開始しない。通常の対話buildはglobal `task: ask`なので、subagentを使う場合は
人間の承認が必要。repo-local subagent自身も`task: deny`で、孫請けから先へ再委任しない。

agentが`MAILBOX_STATUS: ACK <batch ID>`を正確に返した時だけmessageをprocessedへ移す。timeout、
非ゼロ終了、ACK欠落ではinflightへ残し、同じbatchを自動再実行しない。message本文はbatch内で
引用し、untrusted dataとして渡す。REQS、計画、permissions、承認条件より優先しない。

`worker1`を交代する時は、旧instanceをcloseしてから再登録する。

```bash
python3 scripts/agent_mailbox.py close --instance <old-worker1-instance>
python3 scripts/agent_mailbox.py register --role worker1 --task TASK-002 --interval 600
python3 scripts/agent_mailbox.py status --role worker1
```

旧instanceの未読messageは旧inboxに保持され、新instanceへ暗黙転送しない。必要な引継ぎだけ
`type: handoff`として新taskへ送り直す。runtime mailboxはgitignore対象で、重要な判断は
WORKLOG / ExecPlanへ転記する。

## 自己ループ runner（agent_loop）

- `scripts/agent_loop.py` は、headless CLI を goal 達成まで自動で再起動する loop 実行機構。1 起動 = 1 chunk しか進まない CLI に対して人間が「続けて」を打つ作業を代行する。
- loop の定義は `.agent-shared/loops/` の profile（markdown + 簡易 frontmatter）。同梱 profile:
  - `security-review.md`: `SECURITY.md` + security-harness skill 観点の監査 → 重大度順修正の反復。gates は security_smoke など。
  - `design-review.md`: `DESIGN.md` + design-taste-frontend skill 観点の UI 点検 → 改善の反復。gates は対象プロジェクトの lint / build に差し替えて使う。
  - `TEMPLATE.md`: 任意タスク用 scaffold。gates（機械実行できる完了判定）は必須で、空にできない。
- 実行例: `python3 scripts/agent_loop.py --profile .agent-shared/loops/security-review.md --cli codex`（preset: claude / codex / agy / opencode / kilo / cursor / grok。全presetでnative subagent起動をdenyする。runner は model を選ばない。ユーザーが `--model <model-id>` を指定した場合だけ CLI へ転送。`--agent-cmd` で自由指定、`--dry-run` で構成検証のみ）。
- 仕組み: 毎 iteration fresh context で CLI を headless 起動し、エージェントに docs/WORKLOG.md の更新と `LOOP_STATUS: CONTINUE|DONE|BLOCKED` の宣言をさせる。DONE は gates 全 pass の時だけ受理。停止条件は DONE+gates（exit 0）/ BLOCKED・未承認 deviation（2）/ workspace 無変化 stall（3）/ CLI 異常（iteration timeout・非ゼロ終了 + 契約行なし・契約行連続欠落）（4）/ max_iterations（5）/ 保護対象・deviation 記録の改変（6）/ max_runtime 門限（7）。CLI 異常は再試行せず初回で停止する。複数条件が同時成立した場合の検査優先順位は 改変（6）→ 承認待ち（2）→ CLI 異常（4）（改変と承認状態は CLI の生死より優先して人間に見せる）。prompt には runner が解決した絶対 workdir を明示し、必須ファイル不在・必須コマンドの権限拒否時は捏造・迂回せず BLOCKED を宣言させる。
- 通常iteration内でsubagentを起動して待つことは禁止する。必要な場合は状態を記録してBLOCKEDで終了し、上記mailbox dispatcherへ分ける。mailbox確認中のmodel turnは発生しない。
- state はエージェントが docs に書く（docs = working memory 原則）。runner 自身は `.loop/`（gitignore 済み）に prompt / 出力ログを残すだけなので、中断後も同じコマンドの再実行で docs から続きになる。
- 流量制御（2026-07-17）: loop が速く回りすぎて rate limit を短時間で使い切る実害への対策として、profile の `iteration_interval:`（スローモード: iteration 間の最低秒数で消費速度を抑える）と `max_runtime:`（門限モード: run 全体の実時間上限。超過は未完了でも exit 7 の正常停止で、再実行すれば docs から続きになる）を持つ。既定はどちらも 0 = 無効で従来挙動のまま。`--interval` / `--max-runtime` で実行単位に上書きでき、`--max-runtime 0` で profile の門限を外せる。門限は「次の iteration を始めない」ゲートで、実行中の iteration は中断しない（途中 kill は workspace を壊し得るため。1 iteration の上限は iteration_timeout が担う）。rate limit 検知後の自動待機・再開は採用しない（使い切った limit は待っても回復しない）。トークン数ベースの budget も CLI 横断で使用量の出力形式が揃わないため採用せず、時間ベースで代替する。
- 安全策: 各CLIのhooks / permission denyが効いたままのauto-approve水準（例: Claudeは`acceptEdits`、Codexは`--full-auto`）だけを使い、runnerはpush / mergeを行わない。全presetでnative subagentを無効化し、明示的な分担はmailboxへ分離する。Grok presetはweb searchとcross-session memoryも無効化し、`.grok/config.toml`とhookの二層を保つ。0.2.101が最終textを省略した場合は同一sessionへread-onlyのstatus追問を1回行うが、runnerがgateからDONEを推測することはない。
- gate 改変防止: profile の `protect:` に列挙したファイル + profile 自身 + runner 本体を開始時に snapshot し、loop 中の改変を検出したら exit 6 で即停止する。特定モデルへの対策ではなく、自動 loop の完了判定を守る決定論的な共通ガード。
- 上位計画の保持（plan / impl pair）: profile の `plan_file:` / `implementation_log:`（両方指定または両方省略）で、上位モデルの計画を protect したまま実行モデルに実装させる。実行モデルは計画範囲外の変更を impl への `deviation:` 行で提案して止まり、人間が loop 停止中に plan へ `approval:` 行を追記して再開する。承認の正本は protect された plan 側のみ（run 中の承認偽造が機械的に不可能）。未承認 deviation は宣言に関係なく exit 2、deviation 行の消失・変更・重複は exit 6。文書規約は `docs/EXECPLAN_TEMPLATE.md` と execplan skill、設計の経緯は `docs/EXECPLAN_2026-07-13_iterative-plan-handoff.md`。

## マルチエージェント運用（役割分担 + CLI 横断）

このハーネスの「マルチエージェント」は、**7 CLI + 任意モデルが計画 / 実装 / レビューのどの役割でも入れ替え可能**なこと。契約（pair、deviation / approval、review marker）は CLI 非依存の行 marker + runner / gate の機械検証で表現し、特定 CLI の機能に依存しない。設計の経緯は Fable × GPT-5.6 Sol の round 5（WORKLOG 2026-07-13）。

- **役割の標準形**: 計画 = 高性能モデル（`execplan` / `codebase-improvement-audit` skill で pair を作る）→ 実装 = 安価モデル（`implement-from-plan` profile の pair loop）→ レビュー = 実装と**別の CLI / モデル**（`review-against-plan` profile）。
- **pipeline は shell で繋ぐ**（orchestrator は作らない。exit code 契約: 0=成功 / 2=承認待ち・BLOCKED / 3=stall / 4=CLI 異常 / 5=上限 / 6=改変検出 / 7=門限）:

```bash
python3 scripts/agent_loop.py --profile .agent-shared/loops/<topic>.md --cli opencode
case $? in
  0) python3 scripts/agent_loop.py --profile .agent-shared/loops/<topic>-review.md --cli codex ;;
  2) echo "承認待ち / BLOCKED: plan へ approval を追記するか、理由を確認して再実行" ;;
  *) echo "異常停止: .loop/ のログと WORKLOG を確認" ;;
esac
```

- **レビューの契約**: レビュー成果物は第3のファイル `docs/<plan_id>_review-001.md`（再レビューは review-002 と別ファイル。FAIL を上書きしない）。判定は `review: PASS`（行全体一致）/ `review: FAIL | 理由` をちょうど1行。gate は「marker 1行 + PASS 行の完全一致 + review ファイルの plan_id 照合」（prefix 偽装や FAIL 混在は落ちる）。レビュー中は plan / impl / 変更対象コードを profile の `protect:` で保護し、レビュアーの改変を機械的に止める。review には対象 commit を記録し、違う差分をレビューする事故を防ぐ。
- **並列実行**: 同一 workspace での並列 loop は非対応。並列にする場合は plan を独立した pair に分割し、`git worktree` で workspace ごと分離する。**統合担当は1名**に固定し、merge 順・競合解決・全体 gates の再実行を担う。各エージェントによる main への merge は禁止。
- **capability / parity matrix**（検証水準を誇張しない。argv 検証 = smoke の preset invariant、実機 = 実モデルでの契約遵守テスト）:

| CLI | headless 設計対応 | argv 検証 | 実機検証（pair loop 全周回） |
|---|---|---|---|
| Claude Code | ○（`-p` + acceptEdits、`Agent`無効、prompt=stdin） | ○ smoke | ○ 2026-07-14 claude 2.1.207: exit 0。bash は権限拒否でも gates は runner が実行するため完走 |
| Codex | ○（`exec --full-auto`、`multi_agent`無効） | ○ smoke | ○ 2026-07-14 codex 0.144.1: exit 0。加えて 2026-07-11/13 に loop 全周回（gpt-5.6-terra）、review loop（gpt-5.6-luna、FAIL 検出→PASS）、設計議論（gpt-5.6-sol） |
| Antigravity | ○（絶対 `--add-dir` + accept-edits + print-timeout、subagent hook deny） | ○ smoke | ○ 2026-07-14 agy 1.1.1: exit 0。加えて 2026-07-13 に Gemini 3.1 Pro (High) 契約3本合格 |
| Cursor | ○（`-p --trust`、`subagentStart` deny） | ○ smoke | ○ 2026-07-14 cursor-agent 2026.07.01: exit 0（2 iterations） |
| opencode | ○（`run --dir <絶対path> --agent mailbox-worker`、再委任deny） | ○ smoke | ○ 2026-07-17 opencode 1.17.18: mailbox実機ACK。従来pair loopも完走済み |
| Kilo Code | ○（`run --agent mailbox-worker`、**project の kilo.jsonc 必須**） | ○ smoke | ○ 2026-07-14 kilo 7.2.31: exit 0（kilo.jsonc あり）。kilo.jsonc の無い裸ディレクトリでは bash が auto-reject され turn ごと中断し、契約行が出ず exit 4 になる（実測） |
| Grok CLI (xAI) | ○（`--cwd` + `acceptEdits`、web / memory / subagents無効、session status recovery） | ○ smoke | ○ 2026-07-16 grok 0.2.101: 2周、status recovery後にDONE + gate pass、exit 0 |

7 CLIとも実機loopの完走を確認済み。Grok 0.2.101は別fixtureでstatus recoveryを含む2周を確認した。新しいCLI / model buildを本番投入する前は、同様に小さいtaskで1周観察する。

### Safety parity（2026-07-16）

| 軸 | Claude / Codex / opencode / Kilo / Cursor | Grok 0.2.101 |
|---|---|---|
| rules / skills | `AGENTS.md` + shared skills | 同等。`grok inspect`でAGENTSと9 skillsを検出 |
| project permission | 各CLIのhookまたはpermission config | 同等。native 60 rulesをtrust前にload、deny > allowを実測 |
| hook | shared policyをCLI schemaへ変換 | 同等。camelCase / native tool aliasを変換し、理由付きexit 2を実測 |
| unattended loop | DONE + gates、protect、exit code契約 | 同等。status欠落時も同一sessionのmodel宣言を回収し、DONE + gate passでexit 0 |
| network最小化 | CLI固有permission / sandbox | presetでweb searchを外し、native askでdownloadを止める |
| OS filesystem隔離 | CLIごとに差がある。Codexはworkspace sandboxを持つ | **Codex未満**。WSL `/mnt/d`ではGrok `strict`もworkspace外writeを止めなかった |

したがって、ハーネスのrules / permission / hook / loop契約はClaude、opencode、Kilo、Cursorと同じ運用水準。CodexのOS sandboxを含む隔離水準には達していない。未信頼コードを無人実行する場合はCLIを問わずcontainer / VMを使い、Grokでは必須とする。

## CLI 別の運用メモ

- **Antigravity CLI**: terminal-first の実体は `agy`（`antigravity` は GUI launcher の場合があるため headless smoke に使わない）。実機確認は `agy --version`、認証済みなら `agy --add-dir "$PWD" -p "Return exactly OK"`。timeout 時は失敗と決めず `--continue` で継続する。user-level 設定 `~/.gemini/antigravity-cli/settings.json` はテンプレートから書き換えない。
  - `--add-dir` は**必ず絶対 path**で渡す。相対 `.` では agent が workspace に入れず、ファイルを探して `~/.gemini/antigravity-cli/scratch/` に偽の作業ファイルを作って「完了」と記録する挙動を実測した（2026-07-13、Gemini 3.1 Pro）。agent_loop の agy preset は runner が解決した絶対 path を自動で渡す。
  - headless（`-p`）は権限を付与できないコマンド待ちで無出力ハングし得る。`--print-timeout` で CLI 側の待ち時間を制御できる（agent_loop は iteration_timeout に合わせて自動指定）。
  - `invoke_subagent` / `define_subagent`はproject hookが通常時`force_ask`、runnerの`HARNESS_UNATTENDED=1`時denyにする。markerはrunnerの子processだけへ渡し、永続環境変数にはしない。
  - 実行中の観察は `~/.gemini/antigravity-cli/brain/<会話ID>/.system_generated/logs/transcript.jsonl` と `~/.gemini/antigravity-cli/log/cli-*.log` で行える。
- **Codex**: `AGENTS.md` は global → project root → 作業ディレクトリの順に読まれ、近いものが後勝ち。project docs は約 32KiB 上限があるため always-on を短く保つ。`multi_agent = false`がproject既定で、必要な対話sessionだけ`--enable multi_agent`で明示opt-inする。
- **Cursor**: rules は skills へ移行が進んでいるため、`.cursor/rules/` は使わず `AGENTS.md` + `.agents/skills/` に寄せる。CLI の実体は `cursor-agent`（`agent` alias）。headless は `cursor-agent -p` で、未 trust のディレクトリでは `--trust` が必要。hook block 時は「Rejected: Command execution was blocked by a hook.」が返る。`subagentStart`はask非対応なのでproject hookをfail-closed denyにする。
- **opencode / Kilo Code**: project config は `opencode.jsonc` / `kilo.jsonc`。instruction ファイルの指定は不要（`AGENTS.md` を native 検出）。opencode の headless（`run`）は project 判定が cwd と一致しないことがあり、対象外と判定されると external_directory の permission を auto-reject して全ツールが失敗する。`--dir <絶対path>` の明示で回避する（2026-07-13 実測。agent_loop の preset は自動指定）。両presetは`--agent mailbox-worker`も指定し、無人runのsubagent連鎖をdenyする。Kilo の headless は **project の kilo.jsonc が権限の正本**: 無い場所では bash が auto-reject され、最終メッセージなしで turn が中断する（2026-07-14 実測）。テンプレート導入済み repo では同梱の kilo.jsonc（bash 基本 allow + 破壊系 deny + push は ask）で動作する。`--auto`（全権限自動承認）は使わない。
- **Grok CLI (xAI)**: 実体は `grok`（Claude Code 互換の flag 体系）。headless は `-p <prompt>`、workdir は `--cwd <絶対path>` を明示する。`--permission-mode acceptEdits` を使い、`--always-approve` / `bypassPermissions` は使わない。
  - 2026-07-16、grok 0.2.101 / WSL2で再検証した。`.grok/config.toml`はfolder trust前にも読み込まれる。native layerは`.env.*`をsample名も含めて保守的にdenyするため、Grokでenv sampleを読む必要がある場合は機密を含まない別名copyを人間が用意する。
  - folder trust後のClaude互換hookは、Grokの`toolName` / `toolInput`とnative tool aliasを解釈する。無害な`printf`はallowし、同じcommandに`git reset --hard`文字列を入れたcanaryはnative permissionとhookの両方が実行前にblockした。
  - runnerはGit / project rootに`.grok/config.toml`が無ければ起動前に拒否する。実行時は`--disable-web-search --no-memory --no-subagents --max-turns 10`を固定する。最終text欠落時はiteration固有session IDを`--resume`し、`--tools read_file` / `dontAsk`でstatusだけを回収する。status recoveryはfileを変更できず、DONEは従来どおりgates全pass時だけ受理する。
  - 高制約のread-only監査では`--tools read_file`、または`--disallowed-tools run_terminal_cmd`でshell自体を外せる。`run_terminal_command`は0.2.101でもremoval名として効かない。
  - `--sandbox read-only` / `strict`はこのWSL2 `/mnt/d`環境でfilesystem境界にならない。Grokで未信頼codeを実行するならcontainer / VM / 専用mountを使う。case-insensitive filesystemではAGENTS / CLAUDEが大小文字違いで重複検出される点も残る。
- 全 CLI 共通: model は project-level で pin せず、runner も自動選択・自動変更しない。ユーザーが `--model` を指定した時だけその値を CLI へ渡し、省略時は各 CLI の default / user config に任せる。モデル名、推奨用途、reasoning effort、usage 制約は変化が速く CLI ごとに異なるため、ハーネス正本には固定しない。

## Windows / WSL wrapper

- WSL → Windows PowerShell: `scripts/win_pwsh.sh`（inline と `--file <path.ps1>` の両対応。pwsh.exe 優先、無ければ powershell.exe）。
- WSL → Windows 側 Codex: `scripts/win_codex.sh`（`cmd.exe /c codex.cmd` の直書きは PATH 解決が不安定なので禁止。実体指定は `WIN_CODEX_CMD=...`）。
- Windows → WSL: `scripts/wsl_exec.ps1` / `scripts/wsl_exec.cmd`（`-Workdir` は WSL / Windows 両 path 対応、複数コマンドは `-ShellCommand`）。
- 管理者権限（UAC / sudo）が要る操作は wrapper に混ぜず、目的・変更対象・rollback・検証方法を説明し、ユーザーが直前に OK した1コマンドだけ `AGENT_ADMIN_APPROVED=1` を付けて実行する。

## 検証

- 構造 smoke: `bash scripts/smoke_template.sh`（必須ファイル、廃止ファイル不在、stale 参照、skill metadata、mirror 一致、hooks 構文、policy 動作）。Windows wrapper 部分は `TEMPLATE_SMOKE_WINDOWS=0` で skip、`TEMPLATE_SMOKE_WINDOWS_TIMEOUT=20s` で調整。公開済み ZIP と manifest の release asset 照合は release 品質検査で、未リリース差分がある間は必ず fail するため通常実行では skip される。release 作業時だけ `TEMPLATE_SMOKE_RELEASE=1` を付けて有効化する。
- 安全策 smoke: `bash scripts/security_smoke.sh`。
- loop profile の構成検証: `python3 scripts/agent_loop.py --profile <p> --dry-run`。
- skill 追加・変更後は `python3 scripts/sync_shared_skills.py` → smoke の順で確認する。
- OS 通知: `python3 scripts/notify.py "作業が完了しました"`。Windows / WSLは`csc.exe`で`scripts/windows_toast.cs`をWindowsの一時directoryへcompileし、inbox WinRT APIからWindows Terminal名義のtoastと標準通知音を送る。sourceとexeは通知後に削除する。Windows Terminalまたは.NET Framework compilerが無い場合、WSLは`msg.exe`へ、Windows nativeは8秒timeout付きPowerShell NotifyIconから`msg.exe`へ切り替える。macOSは`osascript`、Linuxは`notify-send` + 利用可能なsound backendを使う。全backendが失敗した場合はterminal bell + messageへfallbackする。通知文はXML escapeし、processにはargvまたはenvironment variableで渡す。shell codeとして展開しない。`--dry-run`でOS backendだけ確認できる。

## テンプレート導入手順

1. root 一式を対象 repo のワークスペース表層へコピーする（`Old/` と `.git/` は除く）。
2. `docs/PROJECT_BRIEF.md` をその repo の build / test / run / 制約で埋める。
3. `docs/REQS.md` / `docs/WORKLOG.md` を空 scaffold に戻し、最初のタスクで埋める。
4. `README.md` はプロジェクト本体の README に置き換えてよい（ハーネスの説明はこのファイルが正本）。
5. `bash scripts/smoke_template.sh` で構造が壊れていないことを確認する。
