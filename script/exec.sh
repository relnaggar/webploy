#!/bin/bash
# Start a shell session in the container or run a command in the container.
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && \
  pwd)"
readonly SCRIPT_DIR
. "${SCRIPT_DIR}/lib/utils.sh"
. "${SCRIPT_DIR}/lib/docker-stack.sh"

usage() {
  echo "usage: ${SCRIPT_NAME} [-u USER] [COMMAND]"
}

parse_args() {
  USER_FLAG=""

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -u|--user)
        USER_FLAG="${2:-}"
        if [[ -z "${USER_FLAG}" ]]; then
          err "Error: -u requires a user argument."
          usage
          exit 1
        fi
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        break
        ;;
    esac
  done

  COMMAND="${1:-}"
}

main() {
  parse_args "$@"

  local container_id=$(get_container_id)

  local docker_cmd=(docker exec)
  [[ -n "${USER_FLAG}" ]] && docker_cmd+=("-u" "${USER_FLAG}")
  docker_cmd+=(-it "${container_id}" /bin/bash)
  [[ -n "${COMMAND}" ]] && docker_cmd+=("-c" "${COMMAND}")

  ( IFS=' '; log "${docker_cmd[*]}" )
  "${docker_cmd[@]}"
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  log "start"
  main "$@"
  log "end"
fi
