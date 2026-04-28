# 要件

このファイルは current task の source of truth。初回 bootstrap や handoff では、まずこの内容を現在の依頼で上書きしてから使う。

## 依頼内容

- 依頼:
  - 古い Docker container を uninstall する script を作る。
  - config を引き継いで update する script を作る。
  - Docker では不要なら作らなくてよいが、必要性を判断して進める。
- 背景:
  - Docker では `docker-data/` を消さなければ config は引き継げる。
  - uninstall は container を消す用途として有用。設定データ削除は危険なので確認付きにする。

## 目標

1. Windows / Linux 用の update script を追加し、`docker-data/config.txt` を保持して更新する。
2. Windows / Linux 用の uninstall script を追加し、container を削除する。
3. setup menu と README に update / uninstall の扱いを明記する。

## 非目標

- Bot 本体の Java 実装変更。
- release、push、commit。
- 実際の Bot token / owner ID の設定。

## 制約

- 原則日本語で回答する。
- 既存未コミット変更は巻き戻さない。
- secrets や `.env` 実体には触れない。
- 小タスクのため `EXECPLAN_*.md` は作らない。

## 受け入れ条件

- [x] `update.bat` / `update.sh` を追加する。
- [x] update は `docker-data/config.txt` を残し、`docker-data/runtime` の jar cache だけ削除する。
- [x] `uninstall.bat` / `uninstall.sh` を追加する。
- [x] uninstall は container を削除し、`docker-data/` は既定で残す。
- [x] `setup.bat` / `setup.sh` のメニューに uninstall を追加する。
- [x] README に update / uninstall の扱いを書く。
- [x] 変更範囲に近い構文チェックを通す。

## 未解決事項

- Windows 実機で `.bat` 実行までは未検証。構文とロジックは静的に確認する。

## 仮定

- 今回の依頼は setup script と docs の small task と分類する。
- config 引き継ぎに特別な移行処理は不要。`docker-data/` を残すことが重要。
