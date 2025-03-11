#!/usr/bin/env bats
load "helpers/tests"
load "helpers/containers"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

source ${BATS_TEST_DIRNAME%/}/.env

export BATS_PHP_DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-docker.io/elasticms/base-php:8.4-nginx}"

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

@test "[$TEST_FILE] Loading container-entrypoint.d scripts in Docker Volume" {
  run provision-docker-volume "${BATS_TEST_DIRNAME%/}/bin/container-entrypoint.d/." "${BATS_APP_BIN_VOLUME_NAME}" "/tmp"
  assert_output -l -r 'LOADING OK'
}

@test "[$TEST_FILE] Loading configuration files in Docker Volume" {
  run provision-docker-volume "${BATS_TEST_DIRNAME%/}/config/nginx/sites-enabled/." "${BATS_APP_CFG_VOLUME_NAME}" "/tmp"
  assert_output -l -r 'LOADING OK'
}

@test "[$TEST_FILE] Loading source files in Docker Volume" {
  run provision-docker-volume "${BATS_TEST_DIRNAME%/}/src/." "${BATS_APP_SRC_VOLUME_NAME}" "/tmp"
  assert_output -l -r 'LOADING OK'
}

@test "[$TEST_FILE] Starting MariaDB service" {
  command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.nginx.yml up -d mariadb
}

@test "[$TEST_FILE] Check for MariaDB startup" {
  container_wait_for_healthy mariadb 30
}

@test "[$TEST_FILE] Starting Nginx/PHP stack services (nginx,php)" {
  command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.nginx.yml up -d php
}

@test "[$TEST_FILE] Check for Nginx/PHP startup messages in containers logs" {
  container_wait_for_log php 60 "INFO success: nginx entered RUNNING state"
  container_wait_for_log php 60 "INFO success: php-fpm entered RUNNING state"
  container_wait_for_healthy php 10
}

@test "[$TEST_FILE] Check for (Default) Index page response code 200" {
  retry 12 5 curl_container php :9000/index.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (Default) Index page response message" {
  retry 12 5 curl_container php :9000/index.php -H "Host: default.localhost" -s 
  assert_output -l -r "Docker Base image - Default index.php page"
}

@test "[$TEST_FILE] Check for (App) MariaDB Connection CheckUp response code 200" {
  retry 12 5 curl_container php :9000/check-db.php -H "Host: localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) MariaDB Connection CheckUp response message" {
  retry 12 5 curl_container php :9000/check-db.php -H "Host: localhost" -s 
  assert_output -l -r "Check DB Connection Done."
}

@test "[$TEST_FILE] Check for (App) Index page response code 200" {
  retry 12 5 curl_container php :9000/index.php -H "Host: localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) Index page response message" {
  retry 12 5 curl_container php :9000/index.php -H "Host: localhost" -s
  assert_output -l -r "Application index.php page"
}

@test "[$TEST_FILE] Check for (App) PHPINFO page response code 200" {
  retry 12 5 curl_container php :9000/phpinfo.php -H "Host: localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) PHPINFO page response message" {
  retry 12 5 curl_container php :9000/phpinfo.php -H "Host: localhost" -s
  assert_output -l -r "<h1 class=\"p\">PHP Version ${BATS_PHP_VERSION}</h1>"
}

@test "[$TEST_FILE] Check for (App) Custom response headers" {
  retry 12 5 curl_container php :9000/index.php -H "Host: localhost" -s -I
  assert_output -l -r "Test-Engine: bats"
}

@test "[$TEST_FILE] Check for Vhost Traffic Status Prometheus response code 200" {
  retry 12 5 curl_container php :9090/metrics -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Vhost Traffic Status Prometheus response message" {
  retry 12 5 curl_container php :9090/metrics -H "Host: default.localhost" -s
  assert_output -l -r "# HELP nginx_vts_info Nginx info"
}

@test "[$TEST_FILE] Check for Vhost Traffic Status Monitor Page response code 200" {
  retry 12 5 curl_container php :9090/vts-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Vhost Traffic Status Monitor Page response message" {
  retry 12 5 curl_container php :9090/vts-status -H "Host: default.localhost" -s
  assert_output -l -r "nginx vhost traffic status monitor"
}

@test "[$TEST_FILE] Check for PHP-FPM Ping response code 200" {
  retry 12 5 curl_container php :9090/ping -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for PHP-FPM Ping response message" {
  retry 12 5 curl_container php :9090/ping -H "Host: default.localhost" -s
  assert_output -l -r "pong"
}

@test "[$TEST_FILE] Check for PHP-FPM Status response code 200" {
  retry 12 5 curl_container php :9090/status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for PHP-FPM Status response message" {
  retry 12 5 curl_container php :9090/status -H "Host: default.localhost" -s
  assert_output -l -r "max children reached"
}

@test "[$TEST_FILE] Check for Nginx Stub Status response code 200" {
  retry 12 5 curl_container php :9090/stub-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Nginx Stub Status response message" {
  retry 12 5 curl_container php :9090/stub-status -H "Host: default.localhost" -s
  assert_output -l -r "server accepts handled requests"
}

@test "[$TEST_FILE] Stop all and delete test containers" {
  command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.nginx.yml down -v
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
