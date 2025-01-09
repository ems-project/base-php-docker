#!/usr/bin/env bats
load "helpers/tests"
load "helpers/containers"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

export BATS_MARIADB_DB_DRIVER="${BATS_MARIADB_DB_DRIVER:-mysql}"
export BATS_MARIADB_DB_HOST="${BATS_MARIADB_DB_HOST:-mariadb}"
export BATS_MARIADB_DB_PORT="${BATS_MARIADB_DB_PORT:-3306}"
export BATS_MARIADB_DB_USER="${BATS_MARIADB_DB_USER:-example}"
export BATS_MARIADB_DB_PASSWORD="${BATS_MARIADB_DB_PASSWORD:-example}"
export BATS_MARIADB_DB_NAME="${BATS_MARIADB_DB_NAME:-example}"
export BATS_MARIADB_ROOT_DB_PASSWORD="${BATS_MARIADB_ROOT_DB_PASSWORD:-p4ssw0rd}"

export BATS_PHP_FPM_MAX_CHILDREN="${BATS_PHP_FPM_MAX_CHILDREN:-4}"
export BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES="${BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES:-128}"
export BATS_CONTAINER_HEAP_PERCENT="${BATS_CONTAINER_HEAP_PERCENT:-0.80}"

export BATS_STORAGE_SERVICE_NAME="mariadb"

export BATS_APP_TMP_VOLUME_NAME=${BATS_APP_TMP_VOLUME_NAME:-app_tmp}
export BATS_APP_VAR_VOLUME_NAME=${BATS_APP_VAR_VOLUME_NAME:-app_var}
export BATS_APP_ETC_VOLUME_NAME=${BATS_APP_ETC_VOLUME_NAME:-app_etc}
export BATS_APP_BIN_VOLUME_NAME=${BATS_APP_BIN_VOLUME_NAME:-app_bin}
export BATS_APP_CFG_VOLUME_NAME=${BATS_APP_CFG_VOLUME_NAME:-app_cfg}
export BATS_APP_SRC_VOLUME_NAME=${BATS_APP_SRC_VOLUME_NAME:-app_src}

export BATS_PHP_DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-docker.io/elasticms/base-php:8.4-nginx}"

export BATS_VARNISH_ENABLED=${BATS_VARNISH_ENABLED:-"false"}

export BATS_UID=$(id -u)

export BATS_CONTAINER_ENGINE="${CONTAINER_ENGINE:-podman}"
export BATS_CONTAINER_COMPOSE_ENGINE="${BATS_CONTAINER_ENGINE} compose"
export BATS_CONTAINER_NETWORK_NAME="${CONTAINER_NETWORK_NAME:-docker_default}"

export BATS_PHP_VERSION="${PHP_VERSION:-8.3.15}"

@test "[$TEST_FILE] Create Docker external volumes (local)" {
  command ${BATS_CONTAINER_ENGINE} volume create -d local ${BATS_APP_TMP_VOLUME_NAME}
  command ${BATS_CONTAINER_ENGINE} volume create -d local ${BATS_APP_VAR_VOLUME_NAME}
  command ${BATS_CONTAINER_ENGINE} volume create -d local ${BATS_APP_ETC_VOLUME_NAME}
  command ${BATS_CONTAINER_ENGINE} volume create -d local ${BATS_APP_BIN_VOLUME_NAME}
  command ${BATS_CONTAINER_ENGINE} volume create -d local ${BATS_APP_CFG_VOLUME_NAME}
  command ${BATS_CONTAINER_ENGINE} volume create -d local ${BATS_APP_SRC_VOLUME_NAME}
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

@test "[$TEST_FILE] Cleanup Docker external volumes (local)" {
  command docker volume rm ${BATS_APP_TMP_VOLUME_NAME}
  command docker volume rm ${BATS_APP_VAR_VOLUME_NAME}
  command docker volume rm ${BATS_APP_ETC_VOLUME_NAME}
  command docker volume rm ${BATS_APP_BIN_VOLUME_NAME}
  command docker volume rm ${BATS_APP_CFG_VOLUME_NAME}
  command docker volume rm ${BATS_APP_SRC_VOLUME_NAME}
}

