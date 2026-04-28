---
name: context-triage
description: 小タスクや調査の入口で、必要最小限の文脈だけを読むために使う。docs の全読や過剰な探索で token を無駄にしたくないときに使う。複雑作業、高リスク変更、handoff 直後では deep path へ切り替える。
---

1. まずタスクを 3 種類に分類する。
   - small: 単一ファイル、単純な質問、限定的な docs 修正
   - medium: 複数ファイルだが局所的、軽い検証あり
   - deep: 複数モジュール横断、履歴依存、停止点再開、高リスク
2. 現在の user request と、その task に関係する project artifact を一次情報として扱い、`docs/REQS.md` を先に更新する。
3. `small` なら fast path を使う。
   - 先に読むのは `docs/PROJECT_BRIEF.md` と更新済み `docs/REQS.md` だけ
   - `docs/PROJECT_BRIEF.md` が scaffold / stale なら、repo 実態に合わせて最小限更新する
   - 必要になったときだけ `rg` / `sed` で周辺コードや docs を狭く読む
4. `medium` なら fast path に加えて `docs/INDEX.md` を読む。
5. `deep` なら `docs/AGENT_BOOTSTRAP.md` の deep path に従い、必要なら `docs/EXECPLAN_*.md` を作る。
6. どの path を選んだか、意図的にまだ読んでいない文書は何かを短く明示する。
7. 文脈が足りずに判断を誤りそうなら、そこで初めて deep path へ昇格する。
