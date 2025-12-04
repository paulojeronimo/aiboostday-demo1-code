#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${PROJECT_DIR}/common.sh"
resolve_env "${1:-}" "$PROJECT_DIR"

commit_hash="unknown"
if command -v git >/dev/null 2>&1 && [ -d "${PROJECT_DIR}/.git" ]; then
  if commit_value="$(cd "$PROJECT_DIR" && git rev-parse --short HEAD)"; then
    commit_hash="$commit_value"
  fi
fi
export NEXT_PUBLIC_APP_COMMIT="$commit_hash"
export NEXT_PUBLIC_APP_ENV="$ENV_NAME"

prepare_env "$ENV_NAME" "$PROJECT_DIR"

default_node_modules="${PROJECT_DIR}/node_modules"
if [ ! -d "$default_node_modules" ]; then
  echo "==> node_modules not found, running npm install..."
  (cd "$PROJECT_DIR" && npm install)
fi

echo "==> Starting npm run dev"
cd "$PROJECT_DIR"
npm run dev
