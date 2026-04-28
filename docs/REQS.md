# 要件

このファイルは current task の source of truth。初回 bootstrap や handoff では、まずこの内容を現在の依頼で上書きしてから使う。

## 依頼内容

- 依頼:
  - Release assets の単体インストールファイルがうまく動かない問題を修正する。
  - ダウンロードした launcher bundle の展開先、Docker 起動後に消してよいファイル / 残すべきファイルを説明する。
- 背景:
  - Windows の単体 installer は zip を取得するが、Docker 起動処理が `setup.bat` ではなく簡易 compose 起動に寄っていた。
  - macOS / Linux の単体 installer は同じフォルダに `setup.command` / `setup.sh` がある前提で、zip 外の単体 asset としては bootstrap できなかった。
  - `docker-data/` はコンテナへ bind mount されるため、削除すると config / playlist / jar cache が消える。

## 目標

1. zip 外の Windows / macOS / Linux 単体 installer が、必要な zip bundle を取得して展開し、展開先の `setup.*` を実行できるようにする。
2. zip bundle 内の `Install.*` も `setup.*` へ委譲し、config 作成 / 編集導線を統一する。
3. README / release body に展開先と削除してよいファイル / 残すべきファイルを明記する。
4. 新しい tag release を作成し、修正版 assets を添付する。

## 非目標

- Bot 本体の Java 実装変更。
- 実際の Bot token / owner ID の設定。
- 既存 release assets の手動差し替え。

## 制約

- 原則日本語で回答する。
- 既存未コミット変更は巻き戻さない。
- secrets や `.env` 実体には触れない。
- 小タスクのため `EXECPLAN_*.md` は作らない。

## 受け入れ条件

- [x] Windows 単体 installer が `JMusicBot-JP-Docker-<tag>/` を展開し、`setup.bat` を実行する。
- [x] macOS 単体 installer が `JMusicBot-JP-Docker-<tag>/` を展開し、`setup.command` を実行する。
- [x] Linux 単体 installer が `JMusicBot-JP-Docker-<tag>/` を展開し、`setup.sh` を実行する。
- [x] README に展開先、`docker-data/` の扱い、削除してよいファイルを明記する。
- [x] Release body に同じ注意を明記する。
- [x] 変更範囲に近い構文チェックを通す。
- [ ] commit / push / release を完了する。

## 未解決事項

- Windows / macOS 実機でのダブルクリック実行までは未検証。構文と bootstrap logic を静的に確認する。

## 仮定

- 今回の依頼は release installer / docs の medium task と分類する。
- 単体 installer の展開先は、installer を置いたフォルダ直下の `JMusicBot-JP-Docker-<tag>/` とする。
- Docker 起動後も、compose 管理と host bind mount のため `JMusicBot-JP-Docker-<tag>/docker-data/` は残す必要がある。
