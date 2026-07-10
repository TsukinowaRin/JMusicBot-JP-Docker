---
description: checkpoint 前に docs と検証と残リスクをまとめる
---

# Checkpoint Pack

この command は、checkpoint を handoff-ready に整えるためのものです。

## Workflow

1. 変更ファイルを特定する。
2. 最小で有効な検証を実行または列挙する。
3. `docs/WORKLOG.md` に目的、変更、コマンド結果、次の一手、ブロッカーを残す。
4. 複雑作業なら `docs/EXECPLAN_*.md` の進捗と判断も更新する。
5. 最後に、実装内容、変更ファイル、検証、設計判断、残タスク、Go/No-Go を短くまとめる。

## Critical Requirements

1. chat 履歴ではなく docs を正とする。
2. 検証していないことは、成功したように書かない。
3. 不要に長い説明より、再開に必要な事実を優先する。
