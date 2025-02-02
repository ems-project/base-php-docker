#!/usr/bin/env bash

log "INFO" "Setup PHP-FPM Pool Configuration File(s) ..."

if [[ "${PHP_FPM_MAX_CHILDREN_AUTO_RESIZING}" == "true" ]]; then

  log "DEBUG" "Running in Docker Container.  This script check memory settings against QoS."
  log "DEBUG" "Initial settings : "
  log "DEBUG" "   pm.max_children=${PHP_FPM_MAX_CHILDREN}"
  log "DEBUG" "   php_value[memory_limit]=${PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES}M"
  log "DEBUG" "   Ratio=${CONTAINER_HEAP_PERCENT}"

  # calculate and set max_clients
  . /usr/local/bin/dynamic_resources
  CALCULATED_CLIENTS=`get_max_clients`
  if [ -n "$CALCULATED_CLIENTS" ]; then
    PHP_FPM_MAX_CHILDREN=$CALCULATED_CLIENTS
    if [ $CALCULATED_CLIENTS -lt 1 ]; then
      exit 1
    fi
  fi

  log "DEBUG" "After calculation : "
  log "DEBUG" "  pm.max_children=${PHP_FPM_MAX_CHILDREN}"
  log "DEBUG" "  php_value[memory_limit]=${PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES}M"
  log "DEBUG" "  Ratio=${CONTAINER_HEAP_PERCENT}"

fi

log "INFO" "PHP-FPM Pool Memory Settings : "
log "INFO" "   > pm.max_children=${PHP_FPM_MAX_CHILDREN}"
log "INFO" "   > php_value[memory_limit]=${PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES}M"

OUTDIR="/app/etc/php/php-fpm.d /app/etc/supervisor.d /app/var/log /app/var/lock /app/var/run/php-fpm"
mkdir -p $OUTDIR

apply-template /app/config/php/php-fpm.d /app/etc/php/php-fpm.d

true
