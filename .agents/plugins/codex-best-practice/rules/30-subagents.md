# Subagents

- subagent は調査、レビュー、テスト切り分け、docs 整理のような境界が明確な作業に使う。
- 直近の実装判断を subagent に丸投げしない。main agent が統合と最終判断を行う。
- 推奨ロールは `docs-maintainer`、`repo-reviewer`、`test-investigator`、`context-keeper`。
- subagent への依頼は具体的な入力、読む範囲、期待出力、禁止事項を短く指定する。
- 旧 Gemini CLI の agents / commands 相当は、Agy では `/agents` と `.agents/skills/` の skill で扱う。
