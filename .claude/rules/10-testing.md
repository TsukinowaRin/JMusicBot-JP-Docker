# テスト方針

- Validate the smallest changed surface that can still catch regressions.
- Prefer project-native test commands over ad-hoc shell pipelines.
- If tests fail for unrelated reasons, record the failure and isolate what was still verified.
- Before finishing, say which checks passed, failed, or were not run.
