#!/bin/bash
# Configure Litestream for continuous SQLite replication to Cloudflare R2.
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && \
  pwd)"
readonly SCRIPT_DIR
. "${SCRIPT_DIR}/lib/utils.sh"
. "${SCRIPT_DIR}/lib/docker-stack.sh"

generate_config() {
  local retention="$1"
  local snapshot_interval="$2"
  shift 2
  local db_paths=("$@")

  local config_path="${SCRIPT_DIR}/../litestream.yml"

  {
    echo "dbs:"
    for db_path in "${db_paths[@]}"; do
      local r2_path
      r2_path="$(basename "${db_path}")"
      echo "  - path: ${db_path}"
      echo "    replicas:"
      echo "      - type: s3"
      echo "        endpoint: https://\${LITESTREAM_R2_ACCOUNT_ID}.r2.cloudflarestorage.com"
      echo "        bucket: \${LITESTREAM_R2_BUCKET}"
      echo "        path: ${r2_path}"
      echo "        retention: ${retention}"
      echo "        snapshot-interval: ${snapshot_interval}"
    done
  } > "${config_path}"

  log "Generated ${config_path}"
}

main() {
  read -rp "Cloudflare account ID: " r2_account_id
  read -rp "R2 bucket name: " r2_bucket
  read -rp "R2 access key ID: " r2_access_key_id
  read -rsp "R2 secret access key: " r2_secret_access_key
  echo

  read -rp "WAL retention period [72h]: " retention
  retention="${retention:-72h}"
  read -rp "Snapshot interval [6h]: " snapshot_interval
  snapshot_interval="${snapshot_interval:-6h}"

  local db_paths=()
  log "Enter each SQLite database path inside the container. Empty line to finish."
  while true; do
    read -rp "Database path (e.g. /var/db/app.sqlite): " db_path
    [[ -n "${db_path}" ]] || break
    db_paths+=("${db_path}")
  done

  if [[ ${#db_paths[@]} -eq 0 ]]; then
    die "At least one database path is required."
  fi

  generate_config "${retention}" "${snapshot_interval}" "${db_paths[@]}"

  set_env_value LITESTREAM_R2_ACCOUNT_ID "${r2_account_id}"
  set_env_value LITESTREAM_R2_BUCKET "${r2_bucket}"
  set_env_value LITESTREAM_ACCESS_KEY_ID "${r2_access_key_id}"
  set_env_value LITESTREAM_SECRET_ACCESS_KEY "${r2_secret_access_key}"
  set_env_value USE_LITESTREAM true

  if docker service ls --filter "name=${STACK_NAME}_litestream" \
      --format '{{.Name}}' | grep -q "${STACK_NAME}_litestream"; then
    log "Litestream already deployed, restarting service to pick up new config..."
    logfun docker service update --force "${STACK_NAME}_litestream"
  else
    log "Deploying with Litestream..."
    "${SCRIPT_DIR}/up.sh"
  fi
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  log "start"
  main "$@"
  log "end"
fi
