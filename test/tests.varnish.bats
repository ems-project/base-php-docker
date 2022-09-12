#!/usr/bin/env bats
load "helpers/tests"
load "helpers/docker"
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

export BATS_PHP_DOCKER_IMAGE_NAME="${APACHE_PRD_DOCKER_IMAGE_NAME:-docker.io/elasticms/base-php-apache}:rc"

export BATS_VARNISH_ENABLED=${BATS_VARNISH_ENABLED:-"true"}
export BATS_VARNISH_VCL_CONF_CUSTOM=${BATS_VARNISH_VCL_CONF_CUSTOM:-"/etc/varnish/bats.vcl"}

@test "[$TEST_FILE] Create Docker external volumes (local)" {
  command docker volume create -d local ${BATS_PHP_SCRIPTS_VOLUME_NAME}
}

@test "[$TEST_FILE] Loading container-entrypoint.d scripts in Docker Volume" {

  for file in ${BATS_TEST_DIRNAME%/}/bin/container-entrypoint.d/* ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    run init_volume $BATS_PHP_SCRIPTS_VOLUME_NAME $file
    assert_output -l -r 'FS-VOLUME COPY OK'

  done
}

@test "[$TEST_FILE] Starting LAMP stack services (apache,mysql,php)" {
  command docker-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.varnish.yml up -d php mysql
}

@test "[$TEST_FILE] Check for startup messages in containers logs" {
  docker_wait_for_log php 60 "INFO success: apache entered RUNNING state"
  docker_wait_for_log php 60 "INFO success: php-fpm entered RUNNING state"
  docker_wait_for_log php 60 "Running PHP script when Docker container start ..."
  docker_wait_for_log php 60 "Running Shell script when Docker container start ..."
  docker_wait_for_log mysql 60 "Starting MySQL"
}

@test "[$TEST_FILE] Check for Index page response code 200" {
  retry 12 5 curl_container php :6081/index.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Index page response message" {
  retry 12 5 curl_container php :6081/index.php -H "Host: default.localhost" -s 
  assert_output -l -r "Docker Base image - Default index.php page"
}

@test "[$TEST_FILE] Check for MySQL Connection CheckUp response code 200" {
  retry 12 5 curl_container php :6081/check-mysql.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for MySQL Connection CheckUp response message" {
  retry 12 5 curl_container php :6081/check-mysql.php -H "Host: default.localhost" -s 
  assert_output -l -r "Check MySQL Connection Done."
}

@test "[$TEST_FILE] Check for Monitoring /real-time-status page response code 200" {
  retry 12 5 curl_container php :6081/real-time-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Monitoring /status page response code 200" {
  retry 12 5 curl_container php :6081/status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Monitoring /server-status page response code 200" {
  retry 12 5 curl_container php :6081/server-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Stop all and delete test containers" {
  command docker-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.varnish.yml stop
  command docker-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.varnish.yml rm -v -f  
}

@test "[$TEST_FILE] Cleanup Docker external volumes (local)" {
  command docker volume rm ${BATS_PHP_SCRIPTS_VOLUME_NAME}
}

