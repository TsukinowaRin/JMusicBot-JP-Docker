# 要件

このファイルは current task の source of truth。初回 bootstrap や handoff では、まずこの内容を現在の依頼で上書きしてから使う。

## 依頼内容

- 依頼:
  - Release assets の単体インストーラーが `Downloads` など実行場所へ依存する設計をやめる。
  - 後から `config.txt` を編集でき、掃除ツールで消えにくい永続領域へ launcher 一式を置く。
- 背景:
  - `Downloads/JMusicBot-JP-Docker-<tag>/` へ展開すると、ユーザーの掃除やセキュリティソフトで削除されうる。
  - Docker named volume に隠すと `config.txt` の手動編集が難しくなる。
  - OS 標準のアプリデータ領域へ置き、その中の `docker-data/` を Docker の `/data` へ bind mount するのが編集しやすく消えにくい。

## 目標

1. Windows 単体 installer は `%LOCALAPPDATA%\JMusicBot-JP-Docker` へ launcher を配置して `setup.bat` を実行する。
2. macOS 単体 installer は `~/Library/Application Support/JMusicBot-JP-Docker` へ launcher を配置して `setup.command` を実行する。
3. Linux 単体 installer は `${XDG_DATA_HOME:-~/.local/share}/jmusicbot-jp-docker` へ launcher を配置して `setup.sh` を実行する。
4. `JMUSICBOT_INSTALL_DIR` で配置先を上書きできるようにする。
5. README / release body に配置先、`docker-data/` の扱い、削除してよいファイルを明記する。
6. 新しい tag release を作成し、修正版 assets を添付する。

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

- [x] Windows installer が `%LOCALAPPDATA%\JMusicBot-JP-Docker` へコピーして `setup.bat` を実行する。
- [x] macOS installer が `~/Library/Application Support/JMusicBot-JP-Docker` へコピーして `setup.command` を実行する。
- [x] Linux installer が `${XDG_DATA_HOME:-~/.local/share}/jmusicbot-jp-docker` へコピーして `setup.sh` を実行する。
- [x] `JMUSICBOT_INSTALL_DIR` で配置先を上書きできる。
- [x] README に配置先、`docker-data/` の扱い、削除してよいファイルを明記する。
- [x] Release body に同じ注意を明記する。
- [x] 変更範囲に近い構文チェックを通す。
- [ ] commit / push / release を完了する。

## 未解決事項

- Windows / macOS 実機でのダブルクリック実行までは未検証。構文と bootstrap logic を静的に確認する。

## 仮定

- 今回の依頼は release installer / docs の medium task と分類する。
- Docker named volume だけに移すのは、後から設定を書き換えにくいため避ける。
- stable install directory 配下の `docker-data/` は残す必要がある。
