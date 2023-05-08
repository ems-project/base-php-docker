#!/usr/bin/env bats
load "helpers/tests"
load "helpers/podman"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

export BATS_DB_DRIVER="${BATS_DB_DRIVER:-mysql}"
export BATS_DB_HOST="${BATS_DB_HOST:-mysql}"
export BATS_DB_PORT="${BATS_DB_PORT:-3306}"
export BATS_DB_USER="${BATS_DB_USER:-example}"
export BATS_DB_PASSWORD="${BATS_DB_PASSWORD:-example}"
export BATS_DB_NAME="${BATS_DB_NAME:-example}"

export BATS_PHP_FPM_MAX_CHILDREN="${BATS_PHP_FPM_MAX_CHILDREN:-4}"
export BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES="${BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES:-128}"
export BATS_CONTAINER_HEAP_PERCENT="${BATS_CONTAINER_HEAP_PERCENT:-0.80}"

export BATS_STORAGE_SERVICE_NAME="mysql"

export BATS_PHP_SCRIPTS_VOLUME_NAME=${BATS_PHP_SCRIPTS_VOLUME_NAME:-php_scripts}

export BATS_PHP_DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-docker.io/elasticms/base-php:8.0-apache}"

export BATS_VARNISH_ENABLED=${BATS_VARNISH_ENABLED:-"false"}
export BATS_VARNISH_VCL_CONF_CUSTOM=${BATS_VARNISH_VCL_CONF_CUSTOM:-"/etc/varnish/bats.vcl"}

export BATS_UID=$(id -u)

@test "[$TEST_FILE] Create Docker external volumes (local)" {
  command podman volume create -d local ${BATS_PHP_SCRIPTS_VOLUME_NAME}
}

@test "[$TEST_FILE] Loading container-entrypoint.d scripts in Docker Volume" {

  run provision-docker-volume-with-podman "${BATS_TEST_DIRNAME%/}/bin/container-entrypoint.d/." "${BATS_PHP_SCRIPTS_VOLUME_NAME}" "/tmp"
  assert_output -l -r 'LOADING OK'

}

@test "[$TEST_FILE] Starting LAMP stack services (apache,mysql,php)" {
  command podman-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.apache.yml up -d php mysql
}

@test "[$TEST_FILE] Check for startup messages in containers logs" {
  podman_wait_for_log php 60 "INFO success: apache entered RUNNING state"
  podman_wait_for_log php 60 "INFO success: php-fpm entered RUNNING state"
  podman_wait_for_log php 60 "Running PHP script when Docker container start ..."
  podman_wait_for_log php 60 "Running Shell script when Docker container start ..."
  podman_wait_for_log mysql 60 "Starting MySQL"
  podman_wait_for_healthy mysql 120
}

@test "[$TEST_FILE] Check for Index page response code 200" {
  retry 12 5 curl_podman_container php :9000/index.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Index page response message" {
  retry 12 5 curl_podman_container php :9000/index.php -H "Host: default.localhost" -s 
  assert_output -l -r "Docker Base image - Default index.php page"
}

@test "[$TEST_FILE] Check for MySQL Connection CheckUp response code 200" {
  retry 12 5 curl_podman_container php :9000/check-mysql.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for MySQL Connection CheckUp response message" {
  retry 12 5 curl_podman_container php :9000/check-mysql.php -H "Host: default.localhost" -s 
  assert_output -l -r "Check MySQL Connection Done."
}

@test "[$TEST_FILE] Check for Monitoring /real-time-status page response code 200" {
  retry 12 5 curl_podman_container php :9000/real-time-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Monitoring /status page response code 200" {
  retry 12 5 curl_podman_container php :9000/status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Monitoring /server-status page response code 200" {
  retry 12 5 curl_podman_container php :9000/server-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Stop PHP test containers" {
  command podman-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.apache.yml stop php
}

@test "[$TEST_FILE] Re-Start PHP test containers with Varnish enabled" {
  export BATS_VARNISH_ENABLED=true
  command podman-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.apache.yml up -d php
}

@test "[$TEST_FILE] Re-Check for startup messages in containers logs" {
  podman_wait_for_log php 60 "INFO success: apache entered RUNNING state"
  podman_wait_for_log php 60 "INFO success: php-fpm entered RUNNING state"
  podman_wait_for_log php 60 "Running PHP script when Docker container start ..."
  podman_wait_for_log php 60 "Running Shell script when Docker container start ..."
  podman_wait_for_log mysql 60 "Starting MySQL"
  podman_wait_for_healthy mysql 120
}

@test "[$TEST_FILE] Re-Check for Index page response code 200 via Varnish" {
  retry 12 5 curl_podman_container php :6081/index.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Re-Check for Index page response message via Varnish" {
  retry 12 5 curl_podman_container php :6081/index.php -H "Host: default.localhost" -s 
  assert_output -l -r "Docker Base image - Default index.php page"
}

@test "[$TEST_FILE] Re-Check for MySQL Connection CheckUp response code 200 via Varnish" {
  retry 12 5 curl_podman_container php :6081/check-mysql.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Re-Check for MySQL Connection CheckUp response message via Varnish" {
  retry 12 5 curl_podman_container php :6081/check-mysql.php -H "Host: default.localhost" -s 
  assert_output -l -r "Check MySQL Connection Done."
}

@test "[$TEST_FILE] Re-Check for Monitoring /real-time-status page response code 200 via Varnish" {
  retry 12 5 curl_podman_container php :6081/real-time-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Re-Check for Monitoring /status page response code 200 via Varnish" {
  retry 12 5 curl_podman_container php :6081/status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Re-Check for Monitoring /server-status page response code 200 via Varnish" {
  retry 12 5 curl_podman_container php :6081/server-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Stop all and delete test containers" {
  command podman-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.apache.yml down -v
}

@test "[$TEST_FILE] Cleanup Docker external volumes (local)" {
  command podman volume rm ${BATS_PHP_SCRIPTS_VOLUME_NAME}
}