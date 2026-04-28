# プロジェクト概要

この文書は fast path で最初に読む repo 概要。
目標は「build/test/run/制約/入口」を 1 画面で把握できること。長い設計説明はここに書かず、必要なら個別 docs へリンクする。

## この repo について

- プロダクト / ライブラリ / サービス:
  - JMusicBot-JP Docker Launcher
- 主目的:
  - `Cosgy-Dev/JMusicBot-JP` の最新 release jar をコンテナ起動時に取得し、Docker で起動するためのランチャーを提供する。
- 主な利用者:
  - JMusicBot-JP を Docker / Docker Compose で運用したいユーザー。
  - この repo の Docker launcher、セットアップスクリプト、agent docs を保守する開発者 / AI エージェント。

## 入口

- 最初に読むもの:
  - `AGENTS.md`
  - `docs/INDEX.md`
  - `README.md`
- 主要ディレクトリ:
  - `scripts/`: container entrypoint、release、WSL / Windows wrapper、template smoke test。
  - `docker-data/`: Bot の設定、プレイリスト、runtime jar cache を置く volume 用ディレクトリ。
  - `docs/`: 要求、作業ログ、handoff、agent 運用ルール。
  - `Old/`: 旧 JMusicBot-JP ソース一式の退避先。
  - `.agents/`, `.claude/`, `.gemini/`: CLI / agent 向けの skills、commands、rules、hooks。
- 主なバイナリ / パッケージ:
  - Docker image: `jmusicbot-jp-launcher:local`
  - GHCR image: `ghcr.io/tsukinowarin/jmusicbot-jp-docker:<tag>`

## Build / Test / Run

- Build:
  - `docker compose build`
  - または `docker compose up -d --build`
- Test:
  - Docker launcher 変更時は `docker compose config` で Compose 構文を確認する。
  - Shell 変更時は `sh -n scripts/entrypoint.sh scripts/release.sh setup.sh setup.command` を確認する。
  - Agent template / wrapper 変更時は `bash scripts/smoke_template.sh` を使う。ただし Windows 側 `cmd.exe` / `codex.cmd` が必要なため、WSL 環境によっては最後の wrapper checks が失敗しうる。
- Smoke:
  - `docker compose up` で初回 `docker-data/config.txt` が生成されることを確認する。
  - `docker compose logs --tail=50` で placeholder token / owner の案内または Bot 起動ログを確認する。
- Lint / Format:
  - `.editorconfig` と `.gitattributes` に従う。通常ファイルは LF、`*.bat` / `*.cmd` / `*.ps1` は CRLF。

## 制約

- 許可する変更:
  - Dockerfile、Compose、setup scripts、entrypoint、docs、agent workflow の保守。
- 禁止する変更:
  - 明示要求なしの `git reset --hard`、`git clean -fd`、main/master への直接 push。
  - secrets、`.env` 実体、Bot token、証明書、秘密鍵の読み書きや出力。
  - 既存の未コミット変更の巻き戻し。
- プラットフォーム制約:
  - Docker Desktop または Docker Engine と `docker compose` が必要。
  - runtime image は Java 25 JRE、`curl`、`jq`、`ffmpeg`、`tini` を使う。
  - Windows / macOS / Linux 向けの setup entrypoint がある。

## 環境メモ

- 必要なランタイム:
  - Docker / Docker Compose。
  - コンテナ内では Eclipse Temurin 25 JRE。
- パッケージマネージャ:
  - Docker image build では Debian `apt-get`。
- 外部サービス:
  - GitHub Releases API: `https://api.github.com/repos/Cosgy-Dev/JMusicBot-JP/releases/latest`
  - GitHub Container Registry。
