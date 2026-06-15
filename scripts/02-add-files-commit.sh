#!/usr/bin/env bash
set -euo pipefail

find_wzj_repo_root() {
  local current probe wzj_root relative first_child
  current="$(pwd -P)"
  probe="$current"

  while [ "$probe" != "/" ]; do
    if [ "$(basename "$probe")" = "wzj" ]; then
      wzj_root="$probe"
      break
    fi
    probe="$(dirname "$probe")"
  done

  if [ -z "${wzj_root:-}" ]; then
    echo "Run this script inside a first-level child directory under a wzj directory." >&2
    exit 3
  fi

  if [ "$current" = "$wzj_root" ]; then
    echo "Run this script inside a first-level child directory under $wzj_root, such as $wzj_root/test." >&2
    exit 3
  fi

  relative="${current#"$wzj_root"/}"
  first_child="${relative%%/*}"
  printf '%s/%s\n' "$wzj_root" "$first_child"
}

build_commit_message() {
  local summary subject body files
  summary="$(git status --porcelain | awk '
    BEGIN { added = 0; modified = 0; deleted = 0; renamed = 0; other = 0 }
    {
      xy = substr($0, 1, 2)
      if (xy == "??") {
        added++
        next
      }
      if (index(xy, "A") > 0) added++
      if (index(xy, "M") > 0) modified++
      if (index(xy, "D") > 0) deleted++
      if (index(xy, "R") > 0) renamed++
      if (xy !~ /[AMDR]/) other++
    }
    END {
      total = added + modified + deleted + renamed + other
      printf "%d|%d|%d|%d|%d|%d", total, added, modified, deleted, renamed, other
    }
  ')"

  IFS='|' read -r total added modified deleted renamed other <<< "$summary"
  subject="chore: publish ${total} local file changes"
  body="Local change summary:
- added: ${added}
- modified: ${modified}
- deleted: ${deleted}
- renamed: ${renamed}
- other: ${other}"

  files="$(git status --porcelain | sed -n '1,30p')"
  if [ -n "$files" ]; then
    body="${body}

Changed files:
${files}"
  fi

  printf '%s\n\n%s\n' "$subject" "$body"
}

repo_root="$(find_wzj_repo_root)"
cd "$repo_root"

repo_name="${REPO_NAME:-wzj-$(basename "$repo_root")}"
branch_name="${BRANCH_NAME:-main}"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI gh is required" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated. Run: gh auth login -h github.com" >&2
  exit 2
fi

if [ ! -d .git ]; then
  echo "Repository root $repo_root has no .git directory. Run scripts/01-bootstrap-and-publish.sh there first." >&2
  exit 3
fi

echo "LOCAL_CHANGES_BEGIN"
git status --short
echo "LOCAL_CHANGES_END"

if [ -z "$(git status --porcelain)" ]; then
  repo_url="$(gh repo view "$repo_name" --json url -q .url)"
  head_id="$(git rev-parse HEAD)"
  echo "NO_CHANGES=true"
  echo "REPO_NAME=$repo_name"
  echo "REPO_ROOT=$repo_root"
  echo "HEAD_COMMIT_ID=$head_id"
  echo "HEAD_COMMIT_URL=$repo_url/commit/$head_id"
  exit 0
fi

if [ -n "${COMMIT_MESSAGE:-}" ]; then
  commit_subject="$COMMIT_MESSAGE"
  commit_body=""
else
  generated_message="$(build_commit_message)"
  commit_subject="$(printf '%s\n' "$generated_message" | sed -n '1p')"
  commit_body="$(printf '%s\n' "$generated_message" | sed '1,2d')"
fi

git add -A
if [ -n "${commit_body:-}" ]; then
  git commit -m "$commit_subject" -m "$commit_body"
else
  git commit -m "$commit_subject"
fi
git push origin "$branch_name"

repo_url="$(gh repo view "$repo_name" --json url -q .url)"
commit_id="$(git rev-parse HEAD)"

echo "REPO_NAME=$repo_name"
echo "REPO_ROOT=$repo_root"
echo "COMMIT_ID=$commit_id"
echo "COMMIT_URL=$repo_url/commit/$commit_id"
