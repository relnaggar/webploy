#!/bin/bash
# Run `certbot` on the container with a post-hook to fix permissions.
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && \
  pwd)"
readonly SCRIPT_DIR
. "${SCRIPT_DIR}/lib/utils.sh"

main() {
  script/exec.sh "certbot --apache --post-hook \"\
    chgrp -R apache2 /etc/letsencrypt/live \
    && chmod -R 750 /etc/letsencrypt/live \
    && chgrp -R apache2 /etc/letsencrypt/archive \
    && chmod -R 750 /etc/letsencrypt/archive \
    && chgrp -R apache2 /etc/letsencrypt/options-ssl-apache.conf \
  \" $@"
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  log "start"
  main "$@"
  log "end"
fi
