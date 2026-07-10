---
name: execplan-workflow
description: 複雑、高リスク、複数モジュール横断、または複数チェックポイントにまたがる作業で使う。要求を docs/REQS.md に正規化し、docs/EXECPLAN_*.md を作成または更新してから、その計画に沿って進める。小さな単一ファイル修正や単純なQ&Aには使わない。
---

1. `docs/INDEX.md`、`docs/REQS.md`、関連する `docs/EXECPLAN_*.md` を読む。
2. `docs/REQS.md` が無い、または古い場合は、要求、制約、受け入れ条件、仮定が明確になるよう更新する。
3. 作業が複雑で active な ExecPlan が無い場合は、`docs/EXECPLAN_<date>_<topic>.md` を作る。
4. ExecPlan は自己完結に保ち、目的、進捗、判断、具体手順、検証、復旧を含める。
5. 高リスクな曖昧さで止まらない限り、逐次確認より計画に沿った前進を優先する。
6. 発見により方針が変わったら、コード変更の前後で `docs/REQS.md` と ExecPlan を更新する。
7. 最後に、実施した検証と残リスクを記録する。
