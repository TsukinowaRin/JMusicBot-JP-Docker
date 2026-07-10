# Safety

- `.env`、秘密鍵、証明書、トークン類は読まない、書かない、出力しない。
- `git reset --hard`、`git clean -fd`、root への `rm -rf`、disk 操作など破壊的コマンドは明示要求なしに使わない。
- hook が deny / ask / force_ask を返した場合は迂回せず、理由を確認して安全な代替手段を選ぶ。
- secrets、権限、hooks、wrapper、release、外部入力を扱う作業では `SECURITY.md` と `.agents/skills/security-harness/` を読む。
- 権限調整は `/permissions` で確認する。project template から user-level settings は書き換えない。
- 既存の未コミット変更は勝手に戻さない。関係ない差分は無視し、衝突する場合だけユーザーに確認する。
