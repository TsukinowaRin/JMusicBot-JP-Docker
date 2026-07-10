---
description: 小タスク向けに fast path で文脈を絞って bootstrap する
---

# Bootstrap Fast

この command は、単純修正や限定調査で docs を読み過ぎないための軽量 bootstrap 用です。

## Workflow

1. まず task size を `small / medium / deep` に分類する。
2. 現在の user request と、その task に関係する project artifact を一次情報として扱い、`docs/REQS.md` を先に更新する。
3. `small` なら `docs/PROJECT_BRIEF.md` と更新済み `docs/REQS.md` だけ読む。
4. `medium` なら上記に `docs/INDEX.md` を追加する。
5. `deep` または handoff 再開なら `docs/AGENT_BOOTSTRAP.md` の deep path に切り替える。
6. `docs/PROJECT_BRIEF.md` が scaffold / stale なら、repo 実態に合わせて最小限更新する。
7. 変更前に必要なコードと docs だけを `rg` / `sed` で狭く読む。
8. 最後に、選んだ path、まだ読んでいない文書、最初の具体的な一手を短くまとめる。

## Critical Requirements

1. 小タスクで `docs/` 全読をしない。
2. stale な `docs/REQS.md` や `docs/PROJECT_BRIEF.md` を current task の source of truth として扱わない。
3. deep path が必要になったら理由を明記する。
4. 回答は日本語で、`結論 / 理由 / 手順` の順にする。
