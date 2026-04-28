# 要件

このファイルは current task の source of truth。初回 bootstrap や handoff では、まずこの内容を現在の依頼で上書きしてから使う。

## 依頼内容

- 依頼:
  - GitHub Release の単体 asset 名を `Install.bat` ではなく、OS が分かる名前へ変更する。
  - zip の中のファイル名は対象外。
- 背景:
  - 現在の release assets は `Install.bat` / `Install.command` / `Install.sh` で、OS が一覧上で分かりづらい。
  - zip bundle の中では既存互換の `Install.*` を残してよい。

## 目標

1. workflow の release upload asset 名を OS 別に分かる名前へ変更する。
2. 既存 release を再実行した場合に旧 asset 名が残らないようにする。
3. README に新しい asset 名を書く。

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

- [x] Windows asset を `Install-JMusicBot-Docker-Windows.bat` にする。
- [x] macOS asset を `Install-JMusicBot-Docker-macOS.command` にする。
- [x] Linux asset を `Install-JMusicBot-Docker-Linux.sh` にする。
- [x] 旧 asset 名 `Install.bat` / `Install.command` / `Install.sh` を release 更新時に削除対象へ入れる。
- [x] 変更範囲に近い構文チェックを通す。

## 未解決事項

- なし。

## 仮定

- 今回の依頼は release workflow と docs の small task と分類する。
- zip bundle 内の `Install.*` は既存導線維持のため名前を変えない。
