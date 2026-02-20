#!/bin/bash
# Run the production server using settings from .env.
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && \
  pwd)"
readonly SCRIPT_DIR
. "${SCRIPT_DIR}/lib/utils.sh"
. "${SCRIPT_DIR}/lib/docker-stack.sh"

usage() {
  echo "usage: ${SCRIPT_NAME} [DOCKER_IMAGE_IDENTIFIER]"
}

parse_args() {
  # optional arguments
  DOCKER_IMAGE_IDENTIFIER="${1:-}"

  if [[ "${DOCKER_IMAGE_IDENTIFIER}" == "-h" || \
    "${DOCKER_IMAGE_IDENTIFIER}" == "--help" || \
    "$#" -gt 1 ]]; then
    usage
    exit 0
  fi  

  # defaults
  if [[ -z "${DOCKER_IMAGE_IDENTIFIER}" ]]; then
    set +e
      DOCKER_IMAGE_IDENTIFIER=$(get_env_value DOCKER_IMAGE_IDENTIFIER)
    set -e
    if [[ -z "${DOCKER_IMAGE_IDENTIFIER}" ]]; then
      err "Error: DOCKER_IMAGE_IDENTIFIER not found in .env or parameter."
      usage
      exit 1
    fi
  fi  
}

main() {
  parse_args "$@"

  # print to confirm
  log "Production docker image set to: ${DOCKER_IMAGE_IDENTIFIER}"

  # remember the image identifier for next time
  set_env_value DOCKER_IMAGE_IDENTIFIER "${DOCKER_IMAGE_IDENTIFIER}"
  
  # export for docker swarm configuration in the docker-compose file
  export DOCKER_IMAGE_IDENTIFIER 

  # pull the image
  logfun docker pull "${DOCKER_IMAGE_IDENTIFIER}"

  # put Docker in Swarm mode if not already
  if docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "^active$"; then
    log "Docker is in Swarm mode"
  else
    logfun docker swarm init
  fi

  command="docker stack deploy -c docker-compose.prod.yml"
  if [[ -n "$(get_env_value USE_CERTBOT)" ]]; then
    command+=" -c docker-compose.certbot.yml"
  fi
  if [[ -n "$(get_env_value USE_SECRETS)" ]]; then
    command+=" -c docker-compose.secrets.yml"
  fi
  if [[ -n "$(get_env_value USE_LITESTREAM)" ]]; then
    command+=" -c docker-compose.litestream.yml"
    export LITESTREAM_R2_ACCOUNT_ID="$(get_env_value LITESTREAM_R2_ACCOUNT_ID)"
    export LITESTREAM_R2_BUCKET="$(get_env_value LITESTREAM_R2_BUCKET)"
    export LITESTREAM_ACCESS_KEY_ID="$(get_env_value LITESTREAM_ACCESS_KEY_ID)"
    export LITESTREAM_SECRET_ACCESS_KEY="$(get_env_value LITESTREAM_SECRET_ACCESS_KEY)"
  fi
  command+=" ${STACK_NAME}"
  log "Running command: ${command}"
  eval "${command}"

  # Wait for all services in the stack to reach their desired replica count
  # before pruning, since stack deploy is asynchronous.
  log "Waiting for stack to stabilize..."
  while docker service ls --filter "label=com.docker.stack.namespace=${STACK_NAME}" \
      --format '{{.Replicas}}' \
      | awk -F'/' '$1 != $2 { found=1 } END { exit !found }'; do
    sleep 3
  done
  log "Stack stabilized"

  logfun docker system prune -f
  logfun docker image ls
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  log "start"
  main "$@"
  log "end"
fi
