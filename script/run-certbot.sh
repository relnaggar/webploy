#!/bin/bash
# Run `certbot` on the container to acquire or renew a certificate.
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && \
  pwd)"
readonly SCRIPT_DIR
. "${SCRIPT_DIR}/lib/utils.sh"

POST_HOOK="\
  echo 'Define CERTBOT_IS_LIVE' > /etc/apache2/conf-enabled/certbot-is-live.conf \
  && apache2ctl graceful \
"

main() {
  if [[ -z "$(get_env_value USE_CERTBOT)" ]]; then
    log "USE_CERTBOT is not set. Please run script/set-up-certbot.sh first."
    exit 1
  fi

  if [[ "${1:-}" == "renew" ]]; then
    shift
    script/exec.sh "certbot renew --post-hook \"${POST_HOOK}\" $@"
  else
    script/exec.sh "certbot certonly --webroot --post-hook \"${POST_HOOK}\" $@"
  fi
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  log "start"
  main "$@"
  log "end"
fi
