#!/usr/bin/env bats
load "helpers/tests"
load "helpers/containers"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

source ${BATS_TEST_DIRNAME%/}/.env

export BATS_PHP_DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-docker.io/elasticms/base-php:8.4-apache}"

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

@test "[$TEST_FILE] Starting Apache/PHP services (apache,php)" {
  command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.apache.yml up -d php
}

@test "[$TEST_FILE] Check for Apache/PHP startup messages in containers logs" {
  container_wait_for_log php 60 "INFO success: apache entered RUNNING state"
  container_wait_for_log php 60 "INFO success: php-fpm entered RUNNING state"
  container_wait_for_healthy php 10
}

@test "[$TEST_FILE] Check for Index page response code 200" {
  retry 12 5 curl_container php :9000/index.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Index page response message" {
  retry 12 5 curl_container php :9000/index.php -H "Host: default.localhost" -s 
  assert_output -l -r "Docker Base image - Default index.php page"
}

@test "[$TEST_FILE] Check for Monitoring /real-time-status page response code 200" {
  retry 12 5 curl_container php :9000/real-time-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Monitoring /status page response code 200" {
  retry 12 5 curl_container php :9000/status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Monitoring /server-status page response code 200" {
  retry 12 5 curl_container php :9000/server-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Stop PHP test containers" {
  command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.apache.yml stop php
}

@test "[$TEST_FILE] Re-Start PHP test containers with Varnish enabled" {
  export BATS_VARNISH_ENABLED=true
  command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.apache.yml up -d php
}

@test "[$TEST_FILE] Re-Check for startup messages in containers logs" {
  container_wait_for_log php 60 "INFO success: apache entered RUNNING state"
  container_wait_for_log php 60 "INFO success: php-fpm entered RUNNING state"
  container_wait_for_log php 60 "INFO success: varnishd entered RUNNING state"
  container_wait_for_log php 60 "INFO success: varnishncsa entered RUNNING state"
  container_wait_for_healthy php 10
}

@test "[$TEST_FILE] Re-Check for Index page response code 200 via Varnish" {
  retry 12 5 curl_container php :6081/index.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Re-Check for Index page response message via Varnish" {
  retry 12 5 curl_container php :6081/index.php -H "Host: default.localhost" -s 
  assert_output -l -r "Docker Base image - Default index.php page"
}

@test "[$TEST_FILE] Re-Check for Monitoring /real-time-status page response code 200 via Varnish" {
  retry 12 5 curl_container php :6081/real-time-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Re-Check for Monitoring /status page response code 200 via Varnish" {
  retry 12 5 curl_container php :6081/status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Re-Check for Monitoring /server-status page response code 200 via Varnish" {
  retry 12 5 curl_container php :6081/server-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Stop all and delete test containers" {
  command ${BATS_CONTAINER_COMPOSE_ENGINE} -f ${BATS_TEST_DIRNAME%/}/docker-compose.apache.yml down -v
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
