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

prompt_trae_session_id() {
  local input

  if [ -n "${TRAE_SESSION_ID:-}" ]; then
    printf '%s\n' "$TRAE_SESSION_ID"
    return
  fi

  if [ ! -t 0 ]; then
    cat >&2 <<'EOF'
缺少必填输入：Trae Session ID

请在终端中直接执行脚本，并按提示输入 Trae Session ID：
  ./scripts/02-add-files-commit.sh

脚本会将你输入的 Trae Session ID 作为本次 git commit message。
EOF
    exit 4
  fi

  while true; do
    printf '请输入 Trae Session ID（将作为本次 commit message）：' >&2
    IFS= read -r input
    if [ -n "$input" ]; then
      printf '%s\n' "$input"
      return
    fi
    echo "Trae Session ID 不能为空，请重新输入。" >&2
  done
}

usage() {
  cat >&2 <<'EOF'
用法：
  ./scripts/02-add-files-commit.sh

说明：
  执行后按提示输入 Trae Session ID。
  脚本会将你输入的 Trae Session ID 作为本次 git commit message。
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "不再支持命令行传入 Trae Session ID，请直接执行脚本后按提示输入。" >&2
      usage
      exit 4
      ;;
  esac
done

trae_session_id="$(prompt_trae_session_id)"

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

git add -A
git commit -m "$trae_session_id"
git push origin "$branch_name"

repo_url="$(gh repo view "$repo_name" --json url -q .url)"
commit_id="$(git rev-parse HEAD)"

echo "REPO_NAME=$repo_name"
echo "REPO_ROOT=$repo_root"
echo "COMMIT_ID=$commit_id"
echo "COMMIT_URL=$repo_url/commit/$commit_id"
