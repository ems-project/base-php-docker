#!/usr/bin/env bats
load "helpers/tests"
load "helpers/docker"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

export BATS_PHP_VERSION="${PHP_VERSION:-7.4.26}"

export BATS_PHP_DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-docker.io/elasticms/base-php:7.4-cli}"

@test "[$TEST_FILE] Test PHP version" {
  run docker run --rm ${BATS_PHP_DOCKER_IMAGE_NAME} -v
  assert_output -l -r "^PHP ${BATS_PHP_VERSION} \(cli\) \(.*\) \( NTS \)"
}

@test "[$TEST_FILE] Testing NPM Version (with unrecognized uid)" {
  run docker run -u 1000 --rm ${BATS_PHP_DOCKER_IMAGE_NAME} npm -v
  assert_output -l -r "^[0-9]+.[0-9]+.[0-9]+*$"
}
