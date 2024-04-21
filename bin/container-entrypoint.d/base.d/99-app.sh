#!/usr/bin/env bash

echo -e "\n  Running Application configuration script(s) ...\n"

if [ ! -f "/app/var/lock/appinit" ]; then

  for f in /app/bin/container-entrypoint.d/*; do
    case "$f" in
      *.sh)     echo "    $0: running $f"; . "$f" ;;
      *.php)    echo "    $0: running $f"; php -f "$f"; echo ;;
      *)        echo "    $0: ignoring $f" ;;
    esac
  done

  touch /app/var/lock/appinit

fi

true
