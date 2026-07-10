---
name: TEMPLATE
max_iterations: 8
stall_limit: 2
iteration_timeout: 1800
gate_timeout: 600
gates_every_iteration: false
gates:
  - git diff --check
---
# <この loop の1文 goal>

任意タスク用の loop profile scaffold。コピーして `<topic>.md` を作り、
goal・手順・完了条件を書き換えてから `scripts/agent_loop.py --profile` に渡す。

frontmatter の意味:
- max_iterations: 反復の上限。超えたら runner が停止する（既定 8）。
- stall_limit: workspace が無変化のまま CONTINUE が続いたら停止する回数（既定 2）。
- iteration_timeout / gate_timeout: 1 iteration / 1 gate の秒数上限。
- gates: 完了判定に使う機械実行コマンド。**空にはできない。**
  「テストが無いから gates も無し」にせず、最低でも smoke や `test -f <成果物>` を書く。
- gates_every_iteration: true にすると毎 iteration gates を回して失敗を即フィードバックする
  （gates が速い場合のみ推奨）。

## 進め方

1. （goal を達成する手順を、1 iteration = 1 chunk になる粒度で書く）
2. 進捗と判断は docs/WORKLOG.md に残す（runner の prompt が毎回指示する）。

## してはいけないこと

- （このタスクで触ってはいけない範囲、禁止コマンドを書く）

## 完了条件

- （gates が pass する以外に、満たすべき条件があれば書く）
