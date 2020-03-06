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

export BATS_STORAGE_SERVICE_NAME="mysql"

export BATS_MYSQL_VOLUME_NAME=${BATS_MYSQL_VOLUME_NAME:-mysql}
export BATS_CLAIR_LOCAL_SCANNER_CONFIG_VOLUME_NAME=${BATS_CLAIR_LOCAL_SCANNER_CONFIG_VOLUME_NAME:-clair_local_scanner}
export BATS_PHP_SCRIPTS_VOLUME_NAME=${BATS_PHP_SCRIPTS_VOLUME_NAME:-php_scripts}
export BATS_PHP_SOCKET_VOLUME_NAME=${BATS_PHP_SOCKET_VOLUME_NAME:-php_socket}
export BATS_SOURCES_VOLUME_NAME=${BATS_SOURCES_VOLUME_NAME:-php_sources}
export BATS_NGINX_CONFIG_VOLUME_NAME=${BATS_NGINX_CONFIG_VOLUME_NAME:-nginx_config}

export BATS_PHP_DOCKER_IMAGE_NAME="${PHP_DOCKER_IMAGE_NAME:-docker.io/elasticms/base-php-fpm}:rc"

@test "[$TEST_FILE] Create Docker external volumes (local)" {
  command docker volume create -d local ${BATS_MYSQL_VOLUME_NAME}
  command docker volume create -d local ${BATS_CLAIR_LOCAL_SCANNER_CONFIG_VOLUME_NAME}
  command docker volume create -d local ${BATS_PHP_SCRIPTS_VOLUME_NAME}
  command docker volume create -d local ${BATS_PHP_SOCKET_VOLUME_NAME}
  command docker volume create -d local ${BATS_SOURCES_VOLUME_NAME}
  command docker volume create -d local ${BATS_NGINX_CONFIG_VOLUME_NAME}
}

@test "[$TEST_FILE] Loading Clair whitelist file in Clair-Local-Scanner FS Docker Volume" {

  for file in clair-whitelist.yml ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    run init_clair_local_scanner_config_volume $BATS_CLAIR_LOCAL_SCANNER_CONFIG_VOLUME_NAME $file
    assert_output -l -r 'FS-VOLUME CLAIR-LOCAL-SCANNER CONFIG COPY OK'

  done
}

@test "[$TEST_FILE] Starting Clair Scanner" {
  command docker-compose -f docker-compose.yml up -d clair_db
  docker_wait_for_log clair_db 120 "database system is ready to accept connections"

  command docker-compose -f docker-compose.yml up -d clair_local_scan
  docker_wait_for_log clair_local_scan 120 "updater service started"
}

@test "[$TEST_FILE] Launch Clair Scan for [ $BATS_PHP_DOCKER_IMAGE_NAME ] Docker Image" {
  export BATS_CLAIR_LOCAL_ENDPOINT_URL="http://$(docker inspect --format '{{ .NetworkSettings.Networks.docker_default.IPAddress }}' clair_local_scan):6060"
  export BATS_CLAIR_LOCAL_SCANNER_IP="clair_local_scanner"
  export BATS_CLAIR_SCAN_DOCKER_IMAGE_NAME="${BATS_PHP_DOCKER_IMAGE_NAME:-docker.io/elasticms/base-php-fpm:rc}"

  run docker-compose -f docker-compose.yml up clair_local_scanner
  assert_success

  run docker cp clair_local_scanner:/opt/clair/config/clair-report.json clair-report.json
  assert_success

  run docker cp clair_local_scanner:/opt/clair/config/clair-report.log clair-report.log
  assert_success

  UNAPPROVED=$(cat clair-report.json | jq '.unapproved | length')
  if [ ${UNAPPROVED:-0} -gt 0 ] ; then
    run cat clair-report.log
    run cat clair-report.json
    assert_failure
  fi

}

@test "[$TEST_FILE] Stop all and delete test containers" {
  command docker-compose -f docker-compose.yml stop
  command docker-compose -f docker-compose.yml rm -v -f  
}

@test "[$TEST_FILE] Cleanup Docker external volumes (local)" {
  command docker volume rm ${BATS_MYSQL_VOLUME_NAME}
  command docker volume rm ${BATS_CLAIR_LOCAL_SCANNER_CONFIG_VOLUME_NAME}
  command docker volume rm ${BATS_PHP_SCRIPTS_VOLUME_NAME}
  command docker volume rm ${BATS_PHP_SOCKET_VOLUME_NAME}
  command docker volume rm ${BATS_SOURCES_VOLUME_NAME}
  command docker volume rm ${BATS_NGINX_CONFIG_VOLUME_NAME}
}
