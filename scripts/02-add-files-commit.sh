#!/usr/bin/env bash
set -euo pipefail

repo_name="${REPO_NAME:-wzj-$(basename "$PWD")}"
branch_name="${BRANCH_NAME:-main}"
commit_message="${COMMIT_MESSAGE:-chore: publish local changes}"

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
  echo "Current directory is not a git repository. Run scripts/01-bootstrap-and-publish.sh first." >&2
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
  echo "HEAD_COMMIT_ID=$head_id"
  echo "HEAD_COMMIT_URL=$repo_url/commit/$head_id"
  exit 0
fi

git add -A
git commit -m "$commit_message"
git push origin "$branch_name"

repo_url="$(gh repo view "$repo_name" --json url -q .url)"
commit_id="$(git rev-parse HEAD)"

echo "REPO_NAME=$repo_name"
echo "COMMIT_ID=$commit_id"
echo "COMMIT_URL=$repo_url/commit/$commit_id"
