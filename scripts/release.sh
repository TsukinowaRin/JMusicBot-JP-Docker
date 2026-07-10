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

git fetch --tags --quiet origin

head_commit="$(git rev-parse HEAD)"
existing_head_tag="$(git tag --points-at HEAD | awk -v base="${tag}" '$0 == base || index($0, base ".") == 1 { print; exit }')"
if [ -n "${existing_head_tag}" ]; then
  release_tag="${existing_head_tag}"
else
  max_patch="$(git tag --list "${tag}*" | awk -v base="${tag}" '
    BEGIN {
      max = -1
    }
    $0 == base {
      if (max < 0) max = 0
      next
    }
    index($0, base ".") == 1 {
      suffix = substr($0, length(base) + 2)
      if (suffix ~ /^[0-9]+$/ && suffix + 0 > max) max = suffix + 0
    }
    END {
      print max
    }
  ')"

  case "${max_patch}" in
    ""|-1)
      release_tag="${tag}"
      ;;
    *)
      release_tag="${tag}.$((max_patch + 1))"
      ;;
  esac

  if git rev-parse -q --verify "refs/tags/${release_tag}" >/dev/null 2>&1; then
    tagged_commit="$(git rev-list -n 1 "${release_tag}")"
    if [ "${tagged_commit}" != "${head_commit}" ]; then
      echo "tag ${release_tag} は既に別 commit を指しています。" >&2
      exit 1
    fi
  else
    git tag -a "${release_tag}" -m "Release ${release_tag}"
  fi
fi

git push -u origin "${branch}"
git push origin "${release_tag}"

echo "Pushed branch ${branch} and tag ${release_tag}."
