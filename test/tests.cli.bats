#!/usr/bin/env bats
load "helpers/tests"
load "helpers/containers"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

export BATS_PHP_VERSION="${PHP_VERSION:-8.3.21}"
export BATS_AWS_CLI_VERSION="${AWS_CLI_VERSION:-2.13.5}"

export BATS_PHP_DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-docker.io/elasticms/base-php:8.3-cli}"

export BATS_CONTAINER_ENGINE="${CONTAINER_ENGINE:-podman}"
export BATS_CONTAINER_COMPOSE_ENGINE="${BATS_CONTAINER_ENGINE} compose"
export BATS_CONTAINER_NETWORK_NAME="${CONTAINER_NETWORK_NAME:-docker_default}"

#
# Containers configuration
#
export BATS_APP_TMP_VOLUME_NAME="app_tmp"
export BATS_APP_ETC_VOLUME_NAME="app_etc"

@test "[$TEST_FILE] Check Docker external Volumes (local)" {

  BATS_CONTAINER_VOLUME_NAMES=("$BATS_APP_TMP_VOLUME_NAME")
  BATS_CONTAINER_VOLUME_NAMES+=("$BATS_APP_ETC_VOLUME_NAME")

  for BATS_CONTAINER_VOLUME_NAME in "${BATS_CONTAINER_VOLUME_NAMES[@]}"; do

    run ${BATS_CONTAINER_ENGINE} volume inspect ${BATS_CONTAINER_VOLUME_NAME}
  
    if [ "$status" -ne 0 ]; then

      run ${BATS_CONTAINER_ENGINE} volume create ${BATS_CONTAINER_VOLUME_NAME}
      [ "$status" -eq 0 ]
  
    fi

  done

}

@test "[$TEST_FILE] Test PHP version" {
  run ${BATS_CONTAINER_ENGINE} run --read-only --rm \
  -v $BATS_APP_TMP_VOLUME_NAME:/app/tmp \
  -v $BATS_APP_ETC_VOLUME_NAME:/app/etc \
  ${BATS_PHP_DOCKER_IMAGE_NAME} -v
  assert_output -l -r "^PHP ${BATS_PHP_VERSION} \(cli\) \(.*\) \(NTS\)"
}

@test "[$TEST_FILE] Testing NPM Version (with unrecognized uid)" {
  run ${BATS_CONTAINER_ENGINE} run -u 1000 --read-only --rm \
  -v $BATS_APP_TMP_VOLUME_NAME:/app/tmp \
  -v $BATS_APP_ETC_VOLUME_NAME:/app/etc \
  ${BATS_PHP_DOCKER_IMAGE_NAME} npm -v
  assert_output -l -r "^[0-9]+.[0-9]+.[0-9]+*$"
}

@test "[$TEST_FILE] Test aws cli version" {
  run ${BATS_CONTAINER_ENGINE} run --read-only --rm \
  -v $BATS_APP_TMP_VOLUME_NAME:/app/tmp \
  -v $BATS_APP_ETC_VOLUME_NAME:/app/etc \
  ${BATS_PHP_DOCKER_IMAGE_NAME} aws --version
  assert_output -l -r "^aws-cli/${BATS_AWS_CLI_VERSION} Python/.* .*$"
}

@test "[$TEST_FILE] Cleanup Docker external Volumes (local)" {

  BATS_CONTAINER_VOLUME_NAMES=("$BATS_APP_TMP_VOLUME_NAME")
  BATS_CONTAINER_VOLUME_NAMES+=("$BATS_APP_ETC_VOLUME_NAME")
  
  for BATS_CONTAINER_VOLUME_NAME in "${BATS_CONTAINER_VOLUME_NAMES[@]}"; do
    run ${BATS_CONTAINER_ENGINE} volume rm ${BATS_CONTAINER_VOLUME_NAME}
  done

}