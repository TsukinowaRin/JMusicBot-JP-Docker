# docs 索引

この `docs/` は、この repo の運用ルールと current task の working memory を置く場所です。現在の user request と task に関係する project artifact で更新しながら使います。
ユーザーが「DocsとAGENTS.mdを読んで」とだけ言った場合でも、`AGENTS.md` と `docs/AGENT_BOOTSTRAP.md` を起点にここへ到達し、自走開始できる構成を保ちます。

## 初回に必読

- `docs/PROJECT_BRIEF.md`
  - リポジトリの入口、主要ディレクトリ、build/test/run 手順
- `docs/REQS.md`
  - 現在の要求と受け入れ条件
- `docs/AGENT_BOOTSTRAP.md`
  - 初回開始手順、読む順序、CLI 差分の入口
- `docs/TOOL_PLAYBOOK.md`
  - 調査、編集、検証、git、安全策の共通ルール
- `docs/WORKLOG.md`
  - 直近の停止点、試行、残タスク
- `docs/HANDOFF_PROTOCOL.md`
  - 途中停止から別エージェントへ引き継ぐための最低基準

## 参照

- `docs/EXECPLAN_*.md`
  - 複雑作業、重要リファクタ、複数モジュール横断変更の実行計画
- `docs/PLANS.md`
  - ExecPlan の必須セクションと運用ルール
- `docs/EXECPLAN_TEMPLATE.md`
  - ExecPlan の雛形
- `docs/DOCS_POLICY.md`
  - docs の置き方、更新ルール、重複を避ける方針
- `docs/AI_AGENT_GUIDE.md`
  - AGENTS / CLAUDE / GEMINI / hooks / skills / agents の役割分担
- `docs/COMPATIBILITY_GUIDE.md`
  - Claude / Codex / Gemini の互換性方針
- `docs/BEST_PRACTICES_SOURCES.md`
  - このテンプレート設計の根拠にした公式ソースと設計メモ
- `docs/START_PROMPT.txt`
  - 新規セッション開始時の短い起動文

## 更新ルール

- 初回セッションは `docs/AGENT_BOOTSTRAP.md` の順序で必読文書を読む。
- `docs/` 全体を読めば、CLI ごとの基本的な使い分けと handoff ルールが把握できる構成を保つ。
- 2回目以降はこの INDEX を起点に必要箇所だけ読む。
- `docs/` 配下のファイルを追加・削除したら、この INDEX を更新する。
