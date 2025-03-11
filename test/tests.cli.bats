#!/usr/bin/env bats
load "helpers/tests"
load "helpers/containers"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

source ${BATS_TEST_DIRNAME%/}/.env

export BATS_PHP_DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-docker.io/elasticms/base-php:8.4-cli}"

export BATS_CONTAINER_ENGINE="${CONTAINER_ENGINE:-podman}"
export BATS_CONTAINER_COMPOSE_ENGINE="${BATS_CONTAINER_ENGINE} compose"

@test "[$TEST_FILE] Check '${BATS_CONTAINER_NETWORK_NAME}' Docker external Network (local)" {

  run ${BATS_CONTAINER_ENGINE} network inspect ${BATS_CONTAINER_NETWORK_NAME}

  if [ "$status" -ne 0 ]; then

    run ${BATS_CONTAINER_ENGINE} network create ${BATS_CONTAINER_NETWORK_NAME}
    [ "$status" -eq 0 ]

  fi

}

@test "[$TEST_FILE] Test PHP version" {
  run ${BATS_CONTAINER_ENGINE} run --rm ${BATS_PHP_DOCKER_IMAGE_NAME} -v
  assert_output -l -r "^PHP ${BATS_PHP_VERSION} \(cli\) \(.*\) \(NTS\)"
}

@test "[$TEST_FILE] Testing NPM Version (with unrecognized uid)" {
  run ${BATS_CONTAINER_ENGINE} run -u 1000 --rm ${BATS_PHP_DOCKER_IMAGE_NAME} npm -v
  assert_output -l -r "^[0-9]+.[0-9]+.[0-9]+*$"
}

@test "[$TEST_FILE] Test aws cli version" {
  run ${BATS_CONTAINER_ENGINE} run --rm ${BATS_PHP_DOCKER_IMAGE_NAME} aws --version
  assert_output -l -r "^aws-cli/${BATS_AWS_CLI_VERSION} Python/.* .*$"
}