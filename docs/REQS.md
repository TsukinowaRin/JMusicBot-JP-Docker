# 要件

このファイルは current task の source of truth。初回 bootstrap や handoff では、まずこの内容を現在の依頼で上書きしてから使う。

## 依頼内容

- 依頼:
  - Windows の単体 `Install-JMusicBot-Docker-Windows.bat` が、どの処理をしているか分かりづらいので改善する。
  - `setup.bat` のメニュー表示で `セットアップ` / `ログを表示` などがコマンドとして誤実行される問題を直す。
  - `.bat` 単体で正常に install できるか確認する。
- 背景:
  - 現状は `Installing ...` の後、PowerShell 内で download / extract / copy が無言に近く、進行中か停止中か判断しづらい。
  - `setup.bat` は `if (...)` ブロック内で `echo 1^) ...` を使っており、Windows batch の解析でメニュー行が壊れて実行される環境がある。

## 目標

1. `Install.bat` が Docker 確認、install dir、temp dir、download URL、download 完了、copy、verify、setup 起動を順番に表示する。
2. `Install.bat` が `setup.bat` / `compose.yaml` / `config.template.txt` の存在を検証してから `setup.bat` を起動する。
3. `setup.bat` のメニュー表示を batch parser に壊されにくい `[1]` 形式へ変更し、`if (...)` ブロック外で表示する。
4. Windows 側 `cmd.exe` で `.bat` 単体の install smoke を行う。
5. 新しい tag release を作成し、修正版 assets を添付する。

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

- [x] `Install.bat` に step 表示を追加する。
- [x] `Install.bat` が install 後に必要ファイルを検証する。
- [x] `setup.bat` のメニューが `[1]` 形式で正しく表示される。
- [x] Windows 側 `cmd.exe` で `.bat` 単体 install smoke を通す。
- [x] 変更範囲に近い構文チェックを通す。
- [x] commit / push / release を完了する。

## 未解決事項

- Windows の GUI ダブルクリック操作までは未検証。`cmd.exe` からの実行で install smoke を行う。

## 仮定

- 今回の依頼は Windows installer / setup menu の medium task と分類する。
- 実 token / owner は設定しない。install smoke は未知 action を渡して `setup.bat` まで到達することを確認する。
