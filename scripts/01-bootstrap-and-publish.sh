#!/usr/bin/env bash
set -euo pipefail

repo_name="${REPO_NAME:-wzj-$(basename "$PWD")}"
branch_name="${BRANCH_NAME:-main}"
commit_message="${INITIAL_COMMIT_MESSAGE:-feat: scaffold sample web project}"

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
  git init -b "$branch_name"
fi

git add .

if ! git diff --cached --quiet; then
  git commit -m "$commit_message"
fi

if git remote get-url origin >/dev/null 2>&1; then
  remote_url="$(git remote get-url origin)"
else
  if gh repo view "$repo_name" >/dev/null 2>&1; then
    remote_url="$(gh repo view "$repo_name" --json sshUrl -q .sshUrl)"
    git remote add origin "$remote_url"
  else
    gh repo create "$repo_name" --public --source=. --remote=origin
    remote_url="$(git remote get-url origin)"
  fi
fi

git branch -M "$branch_name"
git push -u origin "$branch_name"

repo_url="$(gh repo view "$repo_name" --json url -q .url)"
commit_id="$(git rev-parse HEAD)"

echo "REPO_NAME=$repo_name"
echo "REPO_URL=$repo_url"
echo "INITIAL_COMMIT_ID=$commit_id"
echo "INITIAL_COMMIT_URL=$repo_url/commit/$commit_id"
