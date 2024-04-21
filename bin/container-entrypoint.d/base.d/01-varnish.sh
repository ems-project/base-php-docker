#!/usr/bin/env bash

echo -e "  Setup Varnish Configuration File(s) ..."

if [[ "${VARNISH_ENABLED}" == "true" ]]; then

  echo -e "    Configure Varnish ..."

  OUTDIR="/app/var/varnish /app/var/cache/varnish/varnishd /app/var/run/varnish"
  mkdir -p $OUTDIR

  apply-template /app/config/supervisor.d/varnish /app/etc/supervisor.d

  echo -e "    Create Varnish secret file ..."
  if [[ ! -s /app/var/cache/varnish/secret ]]; then
    dd if=/dev/random of=/app/var/cache/varnish/secret count=1
  fi

else

  echo -e "    > Varnish is not enabled.  No configuration must be done."

fi

true
