#!/usr/bin/env bash

echo -e "  Setup PHP-FPM Pool Configuration File(s) ..."

if [[ "${PHP_FPM_MAX_CHILDREN_AUTO_RESIZING}" == "true" ]]; then

  echo -e "    Running in Docker Container.  This script check memory settings against QoS."
  echo -e "    Initial settings : "
  echo -e "      pm.max_children=${PHP_FPM_MAX_CHILDREN}"
  echo -e "      php_value[memory_limit]=${PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES}M"
  echo -e "      Ratio=${CONTAINER_HEAP_PERCENT}"

  # calculate and set max_clients
  . /usr/local/bin/dynamic_resources
  CALCULATED_CLIENTS=`get_max_clients`
  if [ -n "$CALCULATED_CLIENTS" ]; then
    PHP_FPM_MAX_CHILDREN=$CALCULATED_CLIENTS
    if [ $CALCULATED_CLIENTS -lt 1 ]; then
      exit 1
    fi
  fi

  echo -e "    After calculation : "
  echo -e "      pm.max_children=${PHP_FPM_MAX_CHILDREN}"
  echo -e "      php_value[memory_limit]=${PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES}M"
  echo -e "      Ratio=${CONTAINER_HEAP_PERCENT}"

fi

echo -e "    PHP-FPM Pool Memory Settings : "
echo -e "      > pm.max_children=${PHP_FPM_MAX_CHILDREN}"
echo -e "      > php_value[memory_limit]=${PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES}M"

OUTDIR="/app/etc/php/php-fpm.d /app/etc/supervisor.d /app/var/log /app/var/lock /app/var/run/php-fpm"
mkdir -p $OUTDIR

apply-template /app/config/php/php-fpm.d /app/etc/php/php-fpm.d

true
