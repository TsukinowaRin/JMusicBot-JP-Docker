---
name: karpathy-guidelines
description: LLM コーディングでよくある失敗を減らす行動指針。コードを書く・レビューする・リファクタリングするときに使い、過剰な複雑化を避け、変更を必要な場所に絞り、仮定を表に出し、検証可能な成功条件を先に定義する。
---

# Karpathy Guidelines

LLM coding pitfalls を減らす行動指針。日本語で運用し、project-specific instructions と merge して使う。

**Tradeoff:** cautious over fast。trivial task は判断で軽く進める。

1. **Think Before Coding**: assume しない。曖昧さ、複数解釈、tradeoff を表に出し、不明なら聞く。
2. **Simplicity First**: 問題を解く最小コード。未依頼の機能、単発用途の抽象化、不要な柔軟性、不可能ケースのerror handlingを足さない。
3. **Surgical Changes**: 必要な場所だけ触る。隣接コード改善、無関係な整形、未理解コードの削除をしない。自分の変更で生じた不要物だけ片付ける。
4. **Goal-Driven Execution**: 成功条件を先に定義し、テスト、smoke、期待出力で verified になるまで回す。

Working signal: 差分が小さい、過剰設計が減る、実装後ではなく実装前に確認できる。
