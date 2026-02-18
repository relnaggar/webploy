#!/bin/bash
# Set up volumes and environment variables for when using certbot.
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && \
  pwd)"
readonly SCRIPT_DIR
. "${SCRIPT_DIR}/lib/utils.sh"

main() {
  logfun sudo rm -rf .ssl
  unset_env_value USE_CERTBOT
  log "Restarting the production server"
  script/up.sh
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  log "start"
  main "$@"
  log "end"
fi
