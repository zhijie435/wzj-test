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

usage() {
  cat >&2 <<'EOF'
缺少必填参数：--trae-session-id

用法：
  ./scripts/02-add-files-commit.sh --trae-session-id "你的 Trae Session ID"

说明：
  脚本会将 --trae-session-id 的参数值作为本次 git commit message。
EOF
}

trae_session_id="${TRAE_SESSION_ID:-}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --trae-session-id)
      if [ "$#" -lt 2 ] || [ -z "$2" ]; then
        echo "参数 --trae-session-id 不能为空。" >&2
        usage
        exit 4
      fi
      trae_session_id="$2"
      shift 2
      ;;
    --trae-session-id=*)
      trae_session_id="${1#*=}"
      if [ -z "$trae_session_id" ]; then
        echo "参数 --trae-session-id 不能为空。" >&2
        usage
        exit 4
      fi
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "未知参数：$1" >&2
      usage
      exit 4
      ;;
  esac
done

if [ -z "$trae_session_id" ]; then
  usage
  exit 4
fi

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
