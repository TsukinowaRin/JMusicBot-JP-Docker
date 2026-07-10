# Context And Performance

- まず task size を small / medium / deep に分類する。
- small は `docs/PROJECT_BRIEF.md` と更新済み `docs/REQS.md` だけを起点にし、必要になるまで他 docs を読まない。
- medium は task に直結する docs / コードを 1-2 個だけ追加で読む。
- deep / handoff 再開 / 複数モジュール横断では `docs/WORKLOG.md` と `docs/EXECPLAN_*.md` を使う。
- 長文の再説明を避け、繰り返し作業は `.agents/skills/` を使う。
- 調査が大きい場合は `/agents` で subagent に逃がし、main session は実装と判断に集中させる。
