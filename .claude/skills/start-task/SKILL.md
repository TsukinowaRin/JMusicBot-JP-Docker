---
name: start-task
description: タスク開始時の入口で使う。task size を small / medium / deep に分類し、必要最小限の文脈だけ読んで docs/REQS.md を現在の依頼で更新する。docs 全読や過剰な探索で token を無駄にしたくないとき、および handoff 再開の入口で使う。
---

1. task size を分類する。
   - small: 単一ファイル、単純な質問、限定的な docs 修正
   - medium: 複数ファイルだが局所的、軽い検証あり
   - deep: 複数モジュール横断、履歴依存、handoff 再開、高リスク
2. 現在の user request と関係する project artifact を一次情報として扱い、`docs/REQS.md` を先に更新する。stale な REQS を source of truth として扱わない。
3. small: `AGENTS.md`、`docs/PROJECT_BRIEF.md`、更新済み `docs/REQS.md` だけ読んで始める。`docs/PROJECT_BRIEF.md` が scaffold / stale なら repo 実態に合わせて最小限埋める。
4. medium: 上記に加えて、task に直結する docs / コードを 1-2 個だけ `rg` / 部分読みで狭く読む。
5. deep / handoff 再開: `docs/WORKLOG.md` と active な `docs/EXECPLAN_*.md` を読む。計画が無ければ `execplan` skill で作る。
6. 選んだ path、意図的にまだ読んでいない文書、最初の具体的な一手を短く明示する。
7. 文脈不足で判断を誤りそうになったら、その時点で deep へ昇格し、理由を明記する。
