#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${PROJECT_DIR}/deploy.log"

exec > >(tee "$LOG_FILE") 2>&1

KEY_FILE="${PROJECT_DIR}/.private/gh-key"

IN_DEVCONTAINER=false
if [ -f "/dev/.containerenv" ] || [ -f "/.devcontainer" ] || [ -n "${CODESPACE_NAME:-}" ]; then
  IN_DEVCONTAINER=true
fi

if [ "$IN_DEVCONTAINER" = true ]; then
  if [ ! -f "$KEY_FILE" ]; then
    echo "Error: Private SSH key not found at ${KEY_FILE}. Place your private key there to proceed."
    exit 1
  fi
  chmod 600 "$KEY_FILE"
  export GIT_SSH_COMMAND="ssh -i $KEY_FILE -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -F /dev/null"
fi

source "${PROJECT_DIR}/common.sh"
resolve_env "${1:-}" "$PROJECT_DIR"

echo "Using configuration: $ENV_FILE"
source "$ENV_FILE"
prepare_env "$ENV_NAME" "$PROJECT_DIR"

echo "Deploy started with configuration: $1"

require_var() {
  local var_name="$1"
  if [ -z "${!var_name:-}" ]; then
    echo "ERROR: variable ${var_name} not defined. Configure in .env or in the environment."
    exit 1
  fi
}

require_var DEPLOY_REPO_SSH
require_var DEPLOY_BRANCH
require_var DEPLOY_DIR
require_var DEPLOY_PRUNE_REMOTE_BRANCHES
require_var SKIP_APP_API_EXPORT
require_var FRONTEND_URL

DEPLOY_DIR_ABS="$(cd "$PROJECT_DIR" && realpath -m "$DEPLOY_DIR")"
if [ "$DEPLOY_DIR_ABS" = "$PROJECT_DIR" ]; then
  echo "ERROR: DEPLOY_DIR cannot be the project directory."
  exit 1
fi

API_DIR="${PROJECT_DIR}/app/api"
API_DIR_BACKUP="${PROJECT_DIR}/.tmp-app-api-backup"

echo "==> Building Next project (static output in ./out)..."
cd "$PROJECT_DIR"

if ! git diff --quiet --ignore-submodules HEAD --; then
  echo "ERROR: There are uncommitted changes in the local repository. Commit or stash before deploying."
  git status --short
  exit 1
fi

GIT_COMMIT_SHORT="$(git rev-parse --short HEAD 2>/dev/null || true)"
if [ -z "$GIT_COMMIT_SHORT" ]; then
  echo "ERROR: Could not get the commit hash. Make sure there is at least one commit."
  exit 1
fi
export NEXT_PUBLIC_APP_COMMIT="$GIT_COMMIT_SHORT"
echo "==> Using NEXT_PUBLIC_APP_COMMIT=${NEXT_PUBLIC_APP_COMMIT}"

restore_api_dir() {
  if [ -d "$API_DIR_BACKUP" ]; then
    echo "==> Restoring ${API_DIR}..."
    rm -rf "$API_DIR"
    mv "$API_DIR_BACKUP" "$API_DIR"
  fi
}
trap 'restore_api_dir; unset GIT_SSH_COMMAND' EXIT

if [ "${SKIP_APP_API_EXPORT}" = "true" ] && [ -d "$API_DIR" ]; then
  echo "==> Temporarily removing ${API_DIR} for static build..."
  rm -rf "$API_DIR_BACKUP"
  mv "$API_DIR" "$API_DIR_BACKUP"
fi

if [ ! -d "node_modules" ]; then
  echo "==> node_modules not found, running npm install..."
  npm install
fi

npm run build

if [ ! -d "out" ]; then
  echo "ERROR: directory 'out' not found after npm run build."
  exit 1
fi

echo "==> Preparing public repository in ${DEPLOY_DIR_ABS}..."

rm -rf "$DEPLOY_DIR_ABS"
mkdir -p "$DEPLOY_DIR_ABS"
echo "==> Cloning public repository..."
git clone "$DEPLOY_REPO_SSH" "$DEPLOY_DIR_ABS"

git_deploy() {
  git -C "$DEPLOY_DIR_ABS" "$@"
}

TMP_BRANCH="__deploy_tmp__"
echo "==> Creating temporary orphan branch (${TMP_BRANCH})..."
git_deploy checkout --orphan "${TMP_BRANCH}"
git_deploy reset --hard
git_deploy clean -fdx

echo "==> Base path for assets (URLs): '${NEXT_PUBLIC_BASE_PATH:-<root>}'"
TARGET_DIR="$DEPLOY_DIR_ABS"

echo "==> Copying static build from ${PROJECT_DIR}/out to ${TARGET_DIR}..."
rsync -av --delete --exclude '.git' "${PROJECT_DIR}/out/" "${TARGET_DIR}/"

touch "${DEPLOY_DIR_ABS}/.nojekyll"

README_DEPLOY_FILE="${DEPLOY_DIR_ABS}/README.md"
{
  echo "# Frontend URL (${ENV_NAME})"
  echo
  echo "${FRONTEND_URL}"
  echo
  echo "_Generated on $(date -Iseconds)_"
} > "$README_DEPLOY_FILE"
echo "==> Frontend README generated in ${README_DEPLOY_FILE}"

echo "==> Git status after copy:"
git_deploy status

if git_deploy diff --quiet --ignore-submodules --cached HEAD 2>/dev/null; then
  :
fi

git_deploy add -A

if git_deploy diff --cached --quiet 2>/dev/null; then
  echo "==> No changes to commit."
else
  commit_msg="Static deploy of AI Boost Day on $(date -Iseconds)"
  echo "==> Committing: ${commit_msg}"
  git_deploy commit -m "${commit_msg}" || true
fi

git_deploy branch -M "${DEPLOY_BRANCH}"

echo "==> Pushing to branch ${DEPLOY_BRANCH} in ${DEPLOY_REPO_SSH}..."
git_deploy push -f -u origin "${DEPLOY_BRANCH}"

echo "==> Deploy completed."
