#!/usr/bin/env bats
load "helpers/tests"
load "helpers/podman"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

export BATS_PHP_VERSION="${PHP_VERSION:-8.0.27}"

export BATS_PHP_DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-docker.io/elasticms/base-php:8.0-cli}"

@test "[$TEST_FILE] Test PHP version" {
  run podman run --rm ${BATS_PHP_DOCKER_IMAGE_NAME} -v
  assert_output -l -r "^PHP ${BATS_PHP_VERSION} \(cli\) \(.*\) \( NTS \)"
}

@test "[$TEST_FILE] Testing NPM Version (with unrecognized uid)" {
  run podman run -u 1000 --rm ${BATS_PHP_DOCKER_IMAGE_NAME} npm -v
  assert_output -l -r "^[0-9]+.[0-9]+.[0-9]+*$"
}