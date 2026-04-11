# JMusicBot-JP Docker Launcher

このリポジトリは、`Cosgy-Dev/JMusicBot-JP` の最新リリース jar を取得して Docker で起動するためのランチャーです。
アプリ本体の旧ソース一式は `Old/` に退避しています。

## 必要条件

- Docker Desktop または Docker Engine
- `docker compose` が使えること

## かんたん起動

Windows:
- `setup.bat` をダブルクリック

macOS:
- `setup.command` をダブルクリック

Linux / ターミナル起動:
- `./setup.sh`

初回起動では `docker-data/config.txt` が生成されます。
`token` と `owner` を設定してから、もう一度同じスクリプトを実行してください。

`setup.bat` / `setup.command` / `setup.sh` では、次の 2 つを選べます。

- セットアップ / 起動
- 更新

`更新` を選ぶと、既存コンテナを停止し、`docker-data/runtime/` の jar キャッシュを消してから再作成します。
そのため、次回起動時に `Cosgy-Dev/JMusicBot-JP` の最新リリース jar を取り直します。

## 手動起動

```bash
docker compose up -d --build
docker compose logs -f
```

停止:

```bash
docker compose down
```

## 何をしているか

- コンテナ起動時に GitHub Releases API から `Cosgy-Dev/JMusicBot-JP` の最新リリースを取得
- 最新の `*-All.jar` を `docker-data/runtime/` に保存
- `docker-data/config.txt` が無ければテンプレートから自動生成
- 設定済みならその jar を `java --enable-native-access=ALL-UNNAMED -Dnogui=true` で起動

## GitHub Actions

新しい Docker ランチャー用の workflow は `.github/workflows/docker.yml` にあります。
`master` では `latest`、`develop` では `develop` タグとして GHCR へ publish できます。
tag push 時は、その tag 名で GHCR イメージを publish し、GitHub Release も自動作成します。

Codex から release まで完結させる場合は、通常どおり commit/push の後に tag を push するだけで十分です。
