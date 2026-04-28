# 作業ログ

このファイルは current task の停止点と次の一手だけを残す。

## 現在の状態

- 現在の作業:
  - GitHub Release 単体 asset 名の OS 別リネーム。
- 直近の状態:
  - Release workflow の単体 asset 名を `Install-JMusicBot-Docker-Windows.bat` / `Install-JMusicBot-Docker-macOS.command` / `Install-JMusicBot-Docker-Linux.sh` へ変更した。zip 内の `Install.*` は既存互換のため維持。構文チェックは完了。
- 次にやること:
  - 次のユーザー依頼を `docs/REQS.md` に反映してから作業する。
- ブロッカー:
  - なし。
- 次に最初に読む文書:
  - `docs/REQS.md`
- 次に最初に実行するコマンド:
  - `git status --short`

---

## エントリ

### 2026-04-28 15:19 JST

- 目的:
  - GitHub Release の zip 外単体 installer assets を、OS が分かる名前へ変更する。
- 変更:
  - `.github/workflows/docker.yml` の release asset 生成で、`Install.bat` / `Install.command` / `Install.sh` から OS 別の単体 asset をコピー生成するよう変更。
  - upload asset 名を `Install-JMusicBot-Docker-Windows.bat`、`Install-JMusicBot-Docker-macOS.command`、`Install-JMusicBot-Docker-Linux.sh` に変更。
  - 既存 release を更新した場合に旧名 `Install.bat` / `Install.command` / `Install.sh` が残らないよう削除対象へ追加。
  - `README.md` に新しい release asset 名を追記。
  - `docs/REQS.md` を今回依頼で更新。
- コマンドと結果:
  - `sh -n setup.sh setup.command update.sh uninstall.sh scripts/entrypoint.sh scripts/release.sh`: 成功。
  - `docker compose config`: 成功。
  - `sed ... .github/workflows/docker.yml | node --input-type=module --check`: 成功。
  - `git diff --check`: 成功。
- 判断 / 仮定:
  - zip bundle 内は既存導線維持のため `Install.*` のまま残す。
- 未完了:
  - commit、push、release。
- 次:
  - workflow script の構文チェック後、commit して次の tag を release する。
- 次に最初に読む文書:
  - `docs/REQS.md`
- 次に最初に実行するコマンド:
  - `git diff -- .github/workflows/docker.yml README.md docs/REQS.md docs/WORKLOG.md`
- ブロッカー:
  - なし。
- 参照すべきファイル:
  - `.github/workflows/docker.yml`
  - `README.md`

### 2026-04-28 13:46 JST

- 目的:
  - 古い Docker container を削除する uninstall script と、config を引き継ぐ update script を追加する。
- 変更:
  - `update.bat` / `update.sh` を追加し、`setup.bat update` / `setup.sh update` へ委譲。
  - `uninstall.bat` / `uninstall.sh` を追加し、`setup.bat uninstall` / `setup.sh uninstall` へ委譲。
  - `setup.bat` / `setup.sh` に `uninstall` action とメニュー項目を追加。
  - uninstall は `docker compose down --remove-orphans` と `docker rm -f jmusicbot-jp` を実行し、`docker-data/` 削除は確認付きにした。
  - update は `docker-data/config.txt` を残し、`docker-data/runtime` の jar cache だけ消すことを明示。
  - `README.md` に update / uninstall の単体 script とデータ保持方針を追記。
  - `docs/REQS.md` を今回依頼で更新。
- コマンドと結果:
  - `sh -n setup.sh setup.command update.sh uninstall.sh scripts/entrypoint.sh scripts/release.sh`: 成功。
  - `docker compose config`: 成功。
  - `sed ... .github/workflows/docker.yml | node --input-type=module --check`: 成功。
  - `git diff --check -- setup.bat setup.sh update.bat update.sh uninstall.bat uninstall.sh README.md docs/REQS.md docs/WORKLOG.md .github/workflows/docker.yml`: 成功。
- 判断 / 仮定:
  - Docker では config 引き継ぎのための移行処理は不要。`docker-data/` を消さないことが重要。
  - uninstall で設定まで消すのは危険なので、既定では `docker-data/` を残す。
- 未完了:
  - Windows 実機での `.bat` 実行確認は未実行。
- 次:
  - Windows 実機で確認するなら `update.bat`、`uninstall.bat` を実行する。
- 次に最初に読む文書:
  - `docs/REQS.md`
- 次に最初に実行するコマンド:
  - `git status --short`
- ブロッカー:
  - なし。
- 参照すべきファイル:
  - `setup.bat`
  - `setup.sh`
  - `update.bat`
  - `update.sh`
  - `uninstall.bat`
  - `uninstall.sh`
  - `README.md`

### 2026-04-28 13:31 JST

- 目的:
  - `setup.bat` だけで初回設定から Docker 起動まで進めやすくし、Docker 内 jar の config 編集場所を明確にする。
- 変更:
  - `setup.bat` に `config` / `logs` action と 4 択メニューを追加。
  - `setup.bat` が `docker-data\config.txt` を `config.template.txt` から初回作成し、token / owner が未設定なら Notepad で開くよう変更。
  - Notepad を保存して閉じたあと、placeholder が解消されていれば Docker build / start へ進むよう変更。
  - `setup.sh` も `config` / `logs` action、初回 config 作成、placeholder 検出、エディタ起動に対応。
  - `README.md` に `setup.bat` が行う処理と、コンテナ内 `/data/config.txt` はホスト側 `docker-data/config.txt` で編集することを追記。
  - `docs/REQS.md` を今回依頼で更新。
- コマンドと結果:
  - `sh -n setup.sh setup.command scripts/entrypoint.sh scripts/release.sh`: 成功。
  - `docker compose config`: 成功。
  - `sed ... .github/workflows/docker.yml | node --input-type=module --check`: 成功。
  - `git diff --check -- setup.bat setup.sh README.md docs/REQS.md docs/WORKLOG.md .github/workflows/docker.yml`: 成功。
- 判断 / 仮定:
  - Windows では `setup.bat` を主導線にし、実 config は `docker-data\config.txt` を Notepad で編集する。
  - Docker Compose の `./docker-data:/data` mount により、コンテナ内 jar は同じファイルを `/data/config.txt` として読む。
- 未完了:
  - Windows 実機での `setup.bat` / Notepad 起動確認は未実行。
- 次:
  - Windows 実機で確認するなら `setup.bat config`、その後 `setup.bat setup` を実行する。
- 次に最初に読む文書:
  - `docs/REQS.md`
- 次に最初に実行するコマンド:
  - `git status --short`
- ブロッカー:
  - なし。
- 参照すべきファイル:
  - `setup.bat`
  - `setup.sh`
  - `README.md`

### 2026-04-28 13:21 JST

- 目的:
  - JMusicBot-JP upstream release jar を Docker で簡単に使うため、Windows / Linux 両方の setup と `config.txt` 設定方法を明文化する。
- 変更:
  - `README.md` を agent template 説明から JMusicBot-JP Docker Launcher の利用者向け説明へ置換。
  - `README.md` に Windows / Linux / WSL の `setup.*` 手順、GHCR image の `docker run` 手順、`docker-data/config.txt` の必須項目と書式例を追加。
  - `.github/workflows/docker.yml` の Release body に Windows PowerShell / Linux の config 生成、編集、起動手順を追加。
  - `docs/REQS.md` を今回依頼で更新。
- コマンドと結果:
  - `sed -n ... README.md config.template.txt scripts/entrypoint.sh compose.yaml`: 設定ファイル生成と起動仕様を確認。
  - `find . -maxdepth 3 -type f -iname 'Install*'`: 現行 root には `Install.*` が無く、`.tmp-release-standalone/` のみに存在することを確認。
  - `sh -n scripts/entrypoint.sh scripts/release.sh setup.sh setup.command`: 成功。
  - `docker compose config`: 成功。
  - `sed ... .github/workflows/docker.yml | node --input-type=module --check`: GitHub Release body の `github-script` 部分の JavaScript 構文チェック成功。
  - `git diff --check -- README.md .github/workflows/docker.yml docs/REQS.md docs/WORKLOG.md`: 成功。
  - `ruby -e 'require "yaml"; ...'`: `ruby` が無く実行不可。代替として Docker Compose と `github-script` 部分を確認した。
- 判断 / 仮定:
  - 現行 workflow は release asset を生成していないため、今回の README は `setup.*` と GHCR image 利用手順を正とする。
  - 実際に編集すべきファイルは `config.template.txt` ではなく、初回起動後の `docker-data/config.txt`。
- 未完了:
  - なし。
- 次:
  - 次の具体依頼が来たら `docs/REQS.md` を更新し、必要な範囲だけ調査して進める。
- 次に最初に読む文書:
  - `docs/REQS.md`
- 次に最初に実行するコマンド:
  - `git diff -- README.md .github/workflows/docker.yml docs/REQS.md docs/WORKLOG.md`
- ブロッカー:
  - なし。
- 参照すべきファイル:
  - `README.md`
  - `.github/workflows/docker.yml`
  - `config.template.txt`

### 2026-04-28 13:12 JST

- 目的:
  - ユーザー依頼「DocsとAGENTS.mdを読んで」に従い、追加された agent docs と repo 概要を把握する。
- 変更:
  - `docs/PROJECT_BRIEF.md` を現 repo の Docker launcher 概要で最小更新。
  - `docs/REQS.md` を今回依頼の source of truth として更新。
  - `docs/WORKLOG.md` に現在状態と次の一手を記録。
- コマンドと結果:
  - `find . -name AGENTS.md -print`: `./AGENTS.md` を確認。
  - `find . -maxdepth 4 -type f ...`: `docs/`、`CLAUDE.md`、`GEMINI.md`、agent 関連ファイルを確認。
  - `sed -n ... AGENTS.md docs/*.md docs/START_PROMPT.txt`: agent 運用ルールを確認。
  - `sed -n ... README.md Dockerfile compose.yaml scripts/entrypoint.sh setup.* scripts/smoke_template.sh`: repo 実態と run / test 入口を確認。
- 判断 / 仮定:
  - 今回は small task。複雑実装ではないため `EXECPLAN_*.md` は作らない。
  - `scripts/smoke_template.sh` は Windows wrapper checks を含むため、環境依存の検証として扱う。
- 未完了:
  - なし。
- 次:
  - 次の具体依頼が来たら `docs/REQS.md` を更新し、必要な範囲だけ調査して進める。
- 次に最初に読む文書:
  - `docs/REQS.md`
- 次に最初に実行するコマンド:
  - `git status --short`
- ブロッカー:
  - なし。
- 参照すべきファイル:
  - `AGENTS.md`
  - `docs/INDEX.md`
  - `docs/PROJECT_BRIEF.md`
  - `README.md`
