#!/usr/bin/env bats
load "helpers/tests"
load "helpers/containers"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

source ${BATS_TEST_DIRNAME%/}/.env

export BATS_PHP_DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-docker.io/elasticms/base-php:8.4-fpm}"

export BATS_CONTAINER_ENGINE="${CONTAINER_ENGINE:-podman}"
export BATS_CONTAINER_COMPOSE_ENGINE="${BATS_CONTAINER_ENGINE} compose"

@test "[$TEST_FILE] Check '${BATS_CONTAINER_NETWORK_NAME}' Docker external Network (local)" {

  run ${BATS_CONTAINER_ENGINE} network inspect ${BATS_CONTAINER_NETWORK_NAME}

  if [ "$status" -ne 0 ]; then

    run ${BATS_CONTAINER_ENGINE} network create ${BATS_CONTAINER_NETWORK_NAME}
    [ "$status" -eq 0 ]

  fi

}

@test "[$TEST_FILE] Check Docker external Volumes (local)" {

  BATS_CONTAINER_VOLUME_NAMES=("$BATS_APP_TMP_VOLUME_NAME")
  BATS_CONTAINER_VOLUME_NAMES+=("$BATS_APP_VAR_VOLUME_NAME")
  BATS_CONTAINER_VOLUME_NAMES+=("$BATS_APP_ETC_VOLUME_NAME")
  BATS_CONTAINER_VOLUME_NAMES+=("$BATS_APP_BIN_VOLUME_NAME")
  BATS_CONTAINER_VOLUME_NAMES+=("$BATS_APP_CFG_VOLUME_NAME")
  BATS_CONTAINER_VOLUME_NAMES+=("$BATS_APP_SRC_VOLUME_NAME")
  BATS_CONTAINER_VOLUME_NAMES+=("$BATS_NGINX_CONFIG_VOLUME_NAME")

  for BATS_CONTAINER_VOLUME_NAME in "${BATS_CONTAINER_VOLUME_NAMES[@]}"; do

    run ${BATS_CONTAINER_ENGINE} volume inspect ${BATS_CONTAINER_VOLUME_NAME}
  
    if [ "$status" -ne 0 ]; then

      run ${BATS_CONTAINER_ENGINE} volume create ${BATS_CONTAINER_VOLUME_NAME}
      [ "$status" -eq 0 ]
  
    fi

  done

}

@test "[$TEST_FILE] Loading Nginx config files in Docker Volume" {

  run provision-docker-volume "${BATS_TEST_DIRNAME%/}/etc/nginx/conf.d/." "${BATS_NGINX_CONFIG_VOLUME_NAME}" "/tmp"
  assert_output -l -r 'LOADING OK'

}

@test "[$TEST_FILE] Loading source files in Docker Volume" {

  run provision-docker-volume "${BATS_TEST_DIRNAME%/}/src/." "${BATS_APP_SRC_VOLUME_NAME}" "/tmp"
  assert_output -l -r 'LOADING OK'

}

@test "[$TEST_FILE] Loading container-entrypoint.d scripts in Docker Volume" {

  run provision-docker-volume "${BATS_TEST_DIRNAME%/}/bin/container-entrypoint.d/." "${BATS_APP_BIN_VOLUME_NAME}" "/tmp"
  assert_output -l -r 'LOADING OK'

}

@test "[$TEST_FILE] Starting MariaDB service" {
  command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.php-fpm.yml up -d mariadb
}

@test "[$TEST_FILE] Check for MariaDB startup" {
  container_wait_for_healthy mariadb 30
}

@test "[$TEST_FILE] Starting LAMP stack services (nginx,php)" {
  command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.php-fpm.yml up -d php nginx
}

@test "[$TEST_FILE] Check for startup messages in containers logs" {
  container_wait_for_log php 60 "NOTICE: fpm is running, pid 1"
  container_wait_for_log php 60 "Running PHP script when Docker container start ..."
  container_wait_for_log php 60 "Running Shell script when Docker container start ..."
#  container_wait_for_log php 60 "> php_value\[memory_limit\]=128M"
#
#  if [ "${BATS_CONTAINER_ENGINE}" = "docker" ]; then
#    container_wait_for_log php 60 "> pm.max_children=3"
#  else
#    # Autoresizing cannot be tested with Podman until the limits specified in the Compose file are recognized.
#    true
#  fi

}

@test "[$TEST_FILE] Check for (App) PHP Info page response code 200" {
  retry 12 5 curl_container nginx :9000/phpinfo.php -H "Host: localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) Index page response code 200" {
  retry 12 5 curl_container nginx :9000/index.php -H "Host: localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) Index page response message" {
  retry 12 5 curl_container nginx :9000/index.php -H "Host: localhost" -s 
  assert_output -l -r "Application index.php page"
}

@test "[$TEST_FILE] Check for (App) MariaDB Connection CheckUp response code 200" {
  retry 12 5 curl_container nginx :9000/check-db.php -H "Host: localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) MariaDB Connection CheckUp response message" {
  retry 12 5 curl_container nginx :9000/check-db.php -H "Host: localhost" -s 
  assert_output -l -r "Check DB Connection Done."
}

@test "[$TEST_FILE] Stop PHP-FPM test containers" {
  command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.php-fpm.yml stop php
}

# @test "[$TEST_FILE] Re-Start PHP-FPM test containers without PHP-FPM Auto-Sizing" {
#   export BATS_PHP_FPM_MAX_CHILDREN_AUTO_RESIZING=false
#   export BATS_PHP_FPM_MAX_CHILDREN=40
#   export BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES=16
#   command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.php-fpm.yml up -d php
# }

# @test "[$TEST_FILE] Check for startup messages in containers logs 2" {
# 
#   if [ "${BATS_CONTAINER_ENGINE}" = "docker" ]; then
#     container_wait_for_log php 60 "> pm.max_children=40"
#     container_wait_for_log php 60 "> php_value\[memory_limit\]=16M"
#   else
#     # Autoresizing cannot be tested with Podman until the limits specified in the Compose file are recognized.
#     true
#   fi
# 
# }

# @test "[$TEST_FILE] Stop PHP-FPM test containers without PHP-FPM Auto-Sizing" {
#   command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.php-fpm.yml stop php
# }

# @test "[$TEST_FILE] Re-Start PHP-FPM test containers with PHP-FPM Auto-Sizing" {
#   export BATS_PHP_FPM_MAX_CHILDREN_AUTO_RESIZING=true
#   export BATS_PHP_FPM_MAX_CHILDREN=40
#   export BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES=16
#   command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.php-fpm.yml up -d php
# }

# @test "[$TEST_FILE] Check for startup messages in containers logs 3" {
# 
#   if [ "${BATS_CONTAINER_ENGINE}" = "docker" ]; then
#     container_wait_for_log php 60 "> pm.max_children=26"
#     container_wait_for_log php 60 "> php_value\[memory_limit\]=16M"
#   else
#     # Autoresizing cannot be tested with Podman until the limits specified in the Compose file are recognized.
#     true
#   fi
# 
# }

@test "[$TEST_FILE] Stop all and delete test containers" {
  command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.php-fpm.yml down -v
}

@test "[$TEST_FILE] Cleanup Docker external Volumes (local)" {

  BATS_CONTAINER_VOLUME_NAMES=("$BATS_APP_TMP_VOLUME_NAME")
  BATS_CONTAINER_VOLUME_NAMES+=("$BATS_APP_VAR_VOLUME_NAME")
  BATS_CONTAINER_VOLUME_NAMES+=("$BATS_APP_ETC_VOLUME_NAME")
  BATS_CONTAINER_VOLUME_NAMES+=("$BATS_APP_BIN_VOLUME_NAME")
  BATS_CONTAINER_VOLUME_NAMES+=("$BATS_APP_CFG_VOLUME_NAME")
  BATS_CONTAINER_VOLUME_NAMES+=("$BATS_APP_SRC_VOLUME_NAME")
  BATS_CONTAINER_VOLUME_NAMES+=("$BATS_NGINX_CONFIG_VOLUME_NAME")

  for BATS_CONTAINER_VOLUME_NAME in "${BATS_CONTAINER_VOLUME_NAMES[@]}"; do
    run ${BATS_CONTAINER_ENGINE} volume rm ${BATS_CONTAINER_VOLUME_NAME}
  done

}
