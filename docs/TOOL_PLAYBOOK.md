# ツール運用ガイド

この文書は、どの CLI を使っていても大きく外さないための「道具の使い分け」をまとめたもの。

## 言語方針

- 人間向けの回答、レビュー、要約、計画、docs 更新は原則日本語で行う
- ユーザーが明示的に他言語を指定した場合のみ切り替える
- コード、コマンド、設定キー、識別子、外部仕様上の固定語は原文のままでよい

## ファイル探索と読み取り

- ファイル一覧は高速な検索を優先する
  - 例: `rg --files`, `find`, `fd`
- 文字列検索はまず `rg`
- 大きいファイルは必要範囲だけ読む
  - 例: `sed -n '1,200p'`, `rg -n`
- docs は `docs/INDEX.md` 起点で必要箇所だけ読む

## Token / performance

- まず task size を small / medium / deep に分ける
- `small` では `docs/PROJECT_BRIEF.md` と更新済み `docs/REQS.md` を先に読み、必要が出るまで他 docs を開かない
- `medium` では `docs/INDEX.md` を追加し、必要な docs だけ読む
- `deep` または handoff 再開だけ `docs/AGENT_BOOTSTRAP.md` の deep path を使う
- 同じ長文指示を毎回書き直さず、skill / command / start prompt を再利用する
- 大きいファイルやログは全文ではなく必要範囲だけ読む
- Gemini CLI では `GEMINI.md` を短く保ち、session が重いときは `context-audit` や `/stats` を使って文脈を点検する

## 編集

- 変更前に既存パターンを確認する
- 小さく意味のある単位で編集する
- behavior change と docs change を分離しない
- 大きい変更は plan を先に作る

## 検証

- 変更範囲に最も近いテストから回す
- 必要なら build、type-check、lint、smoke test を追加する
- テンプレート全体の点検には `bash scripts/smoke_template.sh` を使う
- 実行できなかった検証は隠さず書く
- finish 前に「何を検証したか」を言語化する

## Git と履歴

- 関係ない差分は戻さない
- `git reset --hard` と `git clean -fd` は禁止
- main/master への直接 push は避ける
- 差分確認は `git diff --stat`, `git diff -- <path>`, `git status --short`

## Web と外部情報

- 変化しやすい情報は公式ソースを優先して確認する
- 最新情報が不要なら repo 内情報を優先する
- 観測した事実、要求、判断は docs に反映し、次のエージェントが chat 履歴なしで追える状態にする

## CLI ごとの差分を確認したいとき

- 役割分担は `docs/AI_AGENT_GUIDE.md`
- 互換方針は `docs/COMPATIBILITY_GUIDE.md`
- Claude Code には `.claude/commands/`、Gemini CLI には `.gemini/commands/` の workflow command がある
- Gemini CLI の reload は `/memory reload`, `/commands reload`, `/agents reload`, `/skills reload`
- Gemini CLI で context bloat が疑わしいときは `.gemini/commands/context-audit.toml` を使う

## WSL から Windows 側ツールを使うとき

- 特定の Windows OpenSSH endpoint や固定 transport を前提にしない
- Windows 側 PowerShell や `codex` を使いたいときは `scripts/win_pwsh.sh` と `scripts/win_codex.sh` を優先する
- `scripts/win_pwsh.sh` は inline の PowerShell コマンドと `--file <path-to-ps1>` の両方を受ける単一 wrapper
- `scripts/win_pwsh.sh` は既定で PowerShell 7 (`pwsh.exe`) を優先し、無ければ `powershell.exe` へフォールバックする
- `scripts/win_codex.sh` は PowerShell 経由ではなく、WSL 側で作業ディレクトリを合わせてから `cmd.exe /d /c codex.cmd` を呼ぶ方針
- 通常運用では Windows OpenSSH を前提にせず、wrapper の direct / `cmd.exe` 経路を標準とする

## Windows から WSL 側ツールを使うとき

- Windows 側の PowerShell / エージェントから WSL repo や Linux toolchain を叩きたいときは `scripts/wsl_exec.ps1` を使う
- `cmd.exe` ベースのエージェントや `cmd` から呼ぶときは `scripts/wsl_exec.cmd` を使う
- 使い方
  - `.\scripts\wsl_exec.ps1 -Workdir <wsl-repo-path> -Exec pwd`
  - `.\scripts\wsl_exec.ps1 -Workdir <windows-repo-path> -Exec git status`
  - `.\scripts\wsl_exec.ps1 -Workdir <wsl-repo-path> -ShellCommand "python3 -m pytest -q"`
  - `.\scripts\wsl_exec.cmd -Workdir <windows-repo-path> -Exec git status`
- `-Workdir` は WSL path と Windows path の両方を受ける
- PowerShell セッションでは `scripts/wsl_exec.ps1`、`cmd` ベースでは `scripts/wsl_exec.cmd` を正規入口にする
- shell 機能や複数コマンドが必要なときは `-ShellCommand` を優先する
- 既定 model の運用と同様に、wrapper も最小に保ち、必要な transport だけを持つ
