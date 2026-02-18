#!/bin/bash
# Set up volumes and environment variables for when using certbot.
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && \
  pwd)"
readonly SCRIPT_DIR
. "${SCRIPT_DIR}/lib/utils.sh"

main() {
  if [[ ! -d ".ssl" ]]; then
    logfun mkdir .ssl
  fi
  if [[ ! -d ".ssl/letsencrypt" ]]; then
    logfun mkdir .ssl/letsencrypt
  fi

  # set certbot config env variable
  if [[ -z "$(get_env_value USE_CERTBOT)" ]]; then
    log "USE_CERTBOT=true >> .env"
    echo "export USE_CERTBOT=true" >> .env
  fi

  # restart the production server
  log "Restarting the production server"
  script/up.sh
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  log "start"
  main "$@"
  log "end"
fi
