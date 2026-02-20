#!/bin/bash
# Restore a SQLite database from its Litestream replica on Cloudflare R2.
# Usage: script/db-restore.sh FILENAME [--timestamp RFC3339_TIMESTAMP]
#   e.g. script/db-restore.sh app.sqlite
#        script/db-restore.sh app.sqlite --timestamp 2026-01-15T10:30:00Z
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && \
  pwd)"
readonly SCRIPT_DIR
. "${SCRIPT_DIR}/lib/utils.sh"
. "${SCRIPT_DIR}/lib/docker-stack.sh"

usage() {
  echo "usage: ${SCRIPT_NAME} FILENAME [--timestamp RFC3339_TIMESTAMP]"
}

parse_args() {
  TIMESTAMP=""

  if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
  fi

  DB_FILENAME="$1"
  shift

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --timestamp)
        TIMESTAMP="${2:-}"
        shift 2
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done
}

wait_for_service() {
  local service_name="$1"
  while docker service ls --filter "name=${service_name}" \
      --format '{{.Replicas}}' \
      | awk -F'/' '$1 != $2 { found=1 } END { exit !found }'; do
    sleep 2
  done
}

main() {
  parse_args "$@"

  local r2_account_id r2_bucket access_key secret_key
  r2_account_id="$(get_env_value LITESTREAM_R2_ACCOUNT_ID)"
  r2_bucket="$(get_env_value LITESTREAM_R2_BUCKET)"
  access_key="$(get_env_value LITESTREAM_ACCESS_KEY_ID)"
  secret_key="$(get_env_value LITESTREAM_SECRET_ACCESS_KEY)"

  local db_filename replica_url tmp_path
  db_filename="${DB_FILENAME}"
  tmp_path="/tmp/${db_filename}"
  replica_url="s3://${r2_bucket}/${db_filename}?endpoint=https://${r2_account_id}.r2.cloudflarestorage.com"

  log "Restoring /var/db/${db_filename} from Cloudflare R2."
  if [[ -n "${TIMESTAMP}" ]]; then
    log "Target timestamp: ${TIMESTAMP}"
  else
    log "Restoring to latest snapshot."
  fi
  if ! docker service ls --filter "name=${STACK_NAME}_litestream" \
      --format '{{.Name}}' | grep -q "${STACK_NAME}_litestream"; then
    die "Litestream service (${STACK_NAME}_litestream) is not running. Is USE_LITESTREAM set in .env?"
  fi

  log "WARNING: The app will be taken offline briefly."
  read -rp "Type 'yes' to continue: " confirm
  [[ "${confirm}" == "yes" ]] || die "Aborted."

  trap 'err "Restore failed. Bringing services back up..."; \
    docker service scale ${STACK_NAME}_litestream=1 ${STACK_NAME}_app=1 || true' ERR

  log "Scaling down services..."
  logfun docker service scale ${STACK_NAME}_app=0 ${STACK_NAME}_litestream=0
  wait_for_service ${STACK_NAME}_app
  wait_for_service ${STACK_NAME}_litestream

  log "Restoring database from ${replica_url}..."
  local restore_flags=(-o "${tmp_path}")
  if [[ -n "${TIMESTAMP}" ]]; then
    restore_flags+=(-timestamp "${TIMESTAMP}")
  fi
  docker run --rm \
    -e "LITESTREAM_ACCESS_KEY_ID=${access_key}" \
    -e "LITESTREAM_SECRET_ACCESS_KEY=${secret_key}" \
    -v /tmp:/tmp \
    litestream/litestream:0.5.8 \
    restore "${restore_flags[@]}" "${replica_url}"

  log "Copying restored database into volume..."
  logfun docker run --rm \
    -v ${STACK_NAME}_db:/var/db \
    -v /tmp:/tmp \
    busybox \
    sh -c "cp /tmp/${db_filename} /var/db/${db_filename} && chown 999:999 /var/db/${db_filename}"

  log "Cleaning up temp file..."
  rm -f "${tmp_path}"

  trap - ERR

  log "Scaling services back up..."
  logfun docker service scale ${STACK_NAME}_litestream=1
  wait_for_service ${STACK_NAME}_litestream
  logfun docker service scale ${STACK_NAME}_app=1
  wait_for_service ${STACK_NAME}_app
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  log "start"
  main "$@"
  log "end"
fi
