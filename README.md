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
