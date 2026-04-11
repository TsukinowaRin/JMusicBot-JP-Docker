#!/usr/bin/env sh
set -eu

UPSTREAM_REPO="${UPSTREAM_REPO:-Cosgy-Dev/JMusicBot-JP}"
UPSTREAM_RELEASE_API="${UPSTREAM_RELEASE_API:-https://api.github.com/repos/${UPSTREAM_REPO}/releases/latest}"

if ! command -v git >/dev/null 2>&1; then
  echo "git が見つかりません。" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl が見つかりません。" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq が見つかりません。" >&2
  exit 1
fi

branch="$(git branch --show-current)"
if [ -z "${branch}" ]; then
  echo "現在のブランチを判定できません。" >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "未コミット変更があります。先に commit してください。" >&2
  exit 1
fi

tag="$(curl -fsSL "${UPSTREAM_RELEASE_API}" | jq -r '.tag_name')"
if [ -z "${tag}" ] || [ "${tag}" = "null" ]; then
  echo "本家 release tag を取得できませんでした。" >&2
  exit 1
fi

echo "Upstream latest tag: ${tag}"

if git rev-parse -q --verify "refs/tags/${tag}" >/dev/null 2>&1; then
  tagged_commit="$(git rev-list -n 1 "${tag}")"
  head_commit="$(git rev-parse HEAD)"
  if [ "${tagged_commit}" != "${head_commit}" ]; then
    echo "tag ${tag} は既に別 commit を指しています。" >&2
    exit 1
  fi
else
  git tag -a "${tag}" -m "Release ${tag}"
fi

git push -u origin "${branch}"
git push origin "${tag}"

echo "Pushed branch ${branch} and tag ${tag}."
