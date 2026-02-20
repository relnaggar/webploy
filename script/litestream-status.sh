#!/bin/bash
# Show Litestream service status and recent replication logs.
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && \
  pwd)"
readonly SCRIPT_DIR
. "${SCRIPT_DIR}/lib/utils.sh"
. "${SCRIPT_DIR}/lib/docker-stack.sh"

main() {
  if ! docker service ls --filter "name=${STACK_NAME}_litestream" \
      --format '{{.Name}}' | grep -q "${STACK_NAME}_litestream"; then
    die "Litestream service (${STACK_NAME}_litestream) is not running."
  fi

  log "Service:"
  docker service ls --filter "name=${STACK_NAME}_litestream"

  echo
  log "Recent logs:"
  docker service logs --tail 50 --timestamps "${STACK_NAME}_litestream" 2>&1
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  log "start"
  main "$@"
  log "end"
fi
