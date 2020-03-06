#!/usr/bin/env bats
load "helpers/tests"
load "helpers/docker"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

export PHP_VERSION=${PHP_VERSION:-7.3.15}
export RELEASE_NUMBER=${RELEASE_NUMBER:-snapshot}
export BUILD_DATE=${BUILD_DATE:-snapshot}
export VCS_REF=${VCS_REF:-snapshot}
export AWS_CLI_VERSION=${AWS_CLI_VERSION:-1.16.207}

export BATS_MYSQL_VOLUME_NAME=${BATS_MYSQL_VOLUME_NAME:-mysql}
export BATS_CLAIR_LOCAL_SCANNER_CONFIG_VOLUME_NAME=${BATS_CLAIR_LOCAL_SCANNER_CONFIG_VOLUME_NAME:-clair_local_scanner}
export BATS_PHP_SCRIPTS_VOLUME_NAME=${BATS_PHP_SCRIPTS_VOLUME_NAME:-php_scripts}
export BATS_PHP_SOCKET_VOLUME_NAME=${BATS_PHP_SOCKET_VOLUME_NAME:-php_socket}
export BATS_SOURCES_VOLUME_NAME=${BATS_SOURCES_VOLUME_NAME:-php_sources}
export BATS_NGINX_CONFIG_VOLUME_NAME=${BATS_NGINX_CONFIG_VOLUME_NAME:-nginx_config}

export BATS_STORAGE_SERVICE_NAME="mysql"

export BATS_PHP_DOCKER_IMAGE_NAME="${PHP_DOCKER_IMAGE_NAME:-docker.io/elasticms/base-php-fpm}:rc"

@test "[$TEST_FILE] Starting PHP [ ${BATS_PHP_DOCKER_IMAGE_NAME} ] Docker image build" {
  command docker-compose -f docker-compose.yml build --no-cache php-fpm
}
