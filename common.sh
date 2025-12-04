#!/usr/bin/env bash
set -euo pipefail

resolve_env() {
  local env_arg="${1:-}"
  local project_dir="$2"

  if [ -z "$env_arg" ]; then
    echo "Error: You must specify an environment name."
    echo "Usage: $0 <env-name>"
    echo "Available files in ${project_dir}/env:"
    ls -1 "${project_dir}/env/" | grep -v "^\." || echo "No files found"
    exit 1
  fi

  local env_file="${project_dir}/env/${env_arg}"
  if [ ! -f "$env_file" ]; then
    echo "Error: file ${env_file} not found."
    exit 1
  fi

  ENV_FILE="$env_file"
  ENV_NAME="$(basename "$env_arg")"
  ENV_NAME="${ENV_NAME%.*}"
}

prepare_env() {
  local env_name="$1"
  local project_dir="$2"

  local env_src="${project_dir}/env/${env_name}"
  local env_target="${project_dir}/.env"
  local private_env="${project_dir}/.private/env/${env_name}"

  if [ ! -f "$env_src" ]; then
    echo "ERROR: file $env_src not found." >&2
    return 1
  fi

  rm -f "$env_target"
  cp "$env_src" "$env_target"

  if [ -f "$private_env" ]; then
    echo "==> Appending ${private_env} to .env"
    cat "$private_env" >> "$env_target"
  fi

  echo "NEXT_PUBLIC_APP_ENV=${env_name}" >> "$env_target"
  if [ -n "${NEXT_PUBLIC_APP_COMMIT:-}" ]; then
    echo "NEXT_PUBLIC_APP_COMMIT=${NEXT_PUBLIC_APP_COMMIT}" >> "$env_target"
  fi

  echo "==> .env created from env/${env_name}${PRIVATE_ENV:+ + .private/env/${env_name}}"
}
