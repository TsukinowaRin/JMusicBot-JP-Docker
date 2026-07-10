# JMusicBot-JP Docker Launcher

このリポジトリは、フォーク元 [`Cosgy-Dev/JMusicBot-JP`](https://github.com/Cosgy-Dev/JMusicBot-JP) の GitHub Release から最新の `*-All.jar` を取得し、Docker で起動するためのランチャーです。

Bot 本体をこのリポジトリでビルドするのではなく、起動時に本家 release jar を取得します。Java や ffmpeg をホストへ直接入れずに、Docker / Docker Compose だけで JMusicBot-JP を動かせます。

## 必要なもの

- Docker Desktop または Docker Engine
- `docker compose` が使える環境
- Discord Bot token
- Bot owner にする Discord user ID

## かんたん起動

Windows:

```bat
setup.bat
```

`setup.bat` は次のことをまとめて行います。

- `docker-data\config.txt` が無ければ `config.template.txt` から作成
- token / owner が未設定なら Notepad で `docker-data\config.txt` を開く
- Notepad を保存して閉じたあと、設定済みなら Docker image を build して起動
- 更新時は `docker-data\runtime` の jar cache を消して upstream の最新 jar を取り直す
- アンインストール時は Docker container を削除し、設定データは既定で残す

macOS:

```bash
./setup.command
```

Linux / WSL:

```bash
chmod +x setup.sh
./setup.sh
```

初回起動では `docker-data/config.txt` が自動生成されます。生成直後は token と owner が未設定なので Bot は起動せず、設定を促すログを出して停止します。

`docker-data/config.txt` を編集してから、同じスクリプトをもう一度実行してください。Windows では `docker-data\config.txt`、Linux / WSL では `docker-data/config.txt` として見えます。

スクリプトのメニュー:

- `1) セットアップ / 起動`
- `2) 更新`
- `3) 設定ファイルを開く`
- `4) ログを表示`
- `5) アンインストール`

## config.txt の設定方法

編集するファイルは `docker-data/config.txt` です。`config.template.txt` は新規生成用のテンプレートなので、通常は直接編集しません。すでに `docker-data/config.txt` が存在する場合、テンプレートを編集しても反映されません。

Docker コンテナ内では、このファイルが `/data/config.txt` として見えます。つまり、jar が Docker 内で動いていても、編集する場所はホスト側の `docker-data/config.txt` です。

最低限、次の 2 行を設定します。

```txt
token = "Discord Bot token をここに貼る"
owner = 123456789012345678
```

書き方の注意:

- `token` は Discord Developer Portal で発行した Bot token です。ユーザートークンは使えません。
- `token` は必ず `"` で囲みます。
- `owner` は Bot 管理者にする Discord user ID です。17 から 18 桁程度の数字を `"` なしで書きます。
- `//` で始まる行はコメントです。
- 文字列は `prefix = "!"` のように `"` で囲みます。
- 真偽値は `true` / `false`、数値は `maxtime = 0` のように書きます。

例:

```txt
token = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
owner = 123456789012345678
prefix = "!"
altprefix = "なし"
status = ONLINE
stayinchannel = false
```

設定後に起動します。

Windows:

```bat
setup.bat
```

Linux / WSL:

```bash
./setup.sh
```

または Docker Compose で直接起動します。

```bash
docker compose up -d --build
docker compose logs -f
```

`docker-data/` はコンテナの `/data` にマウントされます。プレイリストや runtime jar cache もここに保存されるため、コンテナを作り直しても設定は残ります。

## GHCR のイメージを使う

GitHub Actions で GitHub Container Registry へ image を publish します。`master` は `latest`、`develop` は `develop`、tag push は tag 名でも publish されます。

Linux / WSL:

```bash
docker pull ghcr.io/tsukinowarin/jmusicbot-jp-docker:latest
mkdir -p docker-data
docker run --rm \
  -v "$(pwd)/docker-data:/data" \
  ghcr.io/tsukinowarin/jmusicbot-jp-docker:latest
```

Windows PowerShell:

```powershell
docker pull ghcr.io/tsukinowarin/jmusicbot-jp-docker:latest
New-Item -ItemType Directory -Force docker-data
docker run --rm `
  -v "$((Get-Location).Path)\docker-data:/data" `
  ghcr.io/tsukinowarin/jmusicbot-jp-docker:latest
```

この初回実行で `docker-data/config.txt` が生成されます。編集後、常駐起動します。
初回実行は token / owner が未設定のため、`config.txt` を作成したあとにエラー終了する場合があります。その場合でも `docker-data/config.txt` ができていれば正常です。

Linux / WSL:

```bash
docker run -d \
  --name jmusicbot-jp \
  --restart unless-stopped \
  -v "$(pwd)/docker-data:/data" \
  ghcr.io/tsukinowarin/jmusicbot-jp-docker:latest
```

Windows PowerShell:

```powershell
docker run -d `
  --name jmusicbot-jp `
  --restart unless-stopped `
  -v "$((Get-Location).Path)\docker-data:/data" `
  ghcr.io/tsukinowarin/jmusicbot-jp-docker:latest
```

ログ確認:

```bash
docker logs -f jmusicbot-jp
```

停止:

```bash
docker stop jmusicbot-jp
docker rm jmusicbot-jp
```

## 手動起動

このリポジトリを clone してローカルで image を build する場合:

Windows / Linux 共通:

```bash
docker compose up -d --build
docker compose logs -f
```

停止:

```bash
docker compose down
```

## 更新方法

`setup.bat` / `setup.command` / `setup.sh` では、次の 2 つを選べます。

- セットアップ / 起動
- 更新
- アンインストール

`更新` を選ぶと、既存コンテナを停止し、`docker-data/runtime/` の jar cache を削除してから再作成します。`docker-data/config.txt`、プレイリスト、その他の保存データは残るため、設定を引き継いだまま `Cosgy-Dev/JMusicBot-JP` の最新 release jar を取り直せます。

単体スクリプトでも実行できます。

Windows:

```bat
update.bat
```

Linux / WSL:

```bash
chmod +x update.sh
./update.sh
```

手動で同じことをする場合:

Linux / WSL:

```bash
docker compose down
rm -rf docker-data/runtime
docker compose up -d --build --force-recreate
```

Windows PowerShell:

```powershell
docker compose down
Remove-Item -Recurse -Force docker-data\runtime -ErrorAction SilentlyContinue
docker compose up -d --build --force-recreate
```

## アンインストール

Docker では、設定ファイルを `docker-data/` に残しておけば再インストールや更新時にそのまま使えます。そのため、通常のアンインストールではコンテナだけ削除し、`docker-data/` は残します。

Windows:

```bat
uninstall.bat
```

Linux / WSL:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

実行すると `docker compose down --remove-orphans` と `docker rm -f jmusicbot-jp` を行います。最後に `docker-data/` も削除するか確認されます。

- `N` を選ぶ: `docker-data/config.txt`、プレイリスト、保存データを残す。通常はこちら。
- `Y` を選ぶ: `docker-data/` ごと削除する。token / owner / playlists も消える。

## 何をしているか

- コンテナ起動時に GitHub Releases API から `Cosgy-Dev/JMusicBot-JP` の latest release を取得
- release assets の中から `*-All.jar` を探して `docker-data/runtime/` に保存
- `docker-data/config.txt` が無ければ `config.template.txt` から自動生成
- `token` と `owner` が未設定なら、設定を促して停止
- 設定済みなら `java --enable-native-access=ALL-UNNAMED -Dnogui=true -Dconfig.file=/data/config.txt` で jar を起動

## GitHub Actions / Release

Docker launcher 用 workflow は `.github/workflows/docker.yml` にあります。

- `master`: `latest` tag として GHCR へ publish
- `develop`: `develop` tag として GHCR へ publish
- git tag: tag 名と `latest` として GHCR へ publish し、GitHub Release を作成または更新

Release まで進める場合は、作業ツリーを clean にしてから `./scripts/release.sh` を使います。この script は upstream `Cosgy-Dev/JMusicBot-JP` の latest release tag を取得し、この repo の release tag として push します。upstream tag が既にこの repo に存在する場合は、`0.11.0.5` のように末尾へ launcher patch 番号を付けます。

## 注意

- Bot token、OAuth token、パスワード類は公開しないでください。
- `docker-data/config.txt` はローカル設定ファイルです。実 token を入れた状態で commit しないでください。
- `config.template.txt` を更新しても、既存の `docker-data/config.txt` は自動上書きされません。既存設定を変える場合は `docker-data/config.txt` を編集してください。
