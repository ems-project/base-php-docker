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

export BATS_PHP_FPM_MAX_CHILDREN_AUTO_RESIZING="${BATS_PHP_FPM_MAX_CHILDREN_AUTO_RESIZING:-true}"
export BATS_PHP_FPM_MAX_CHILDREN="${BATS_PHP_FPM_MAX_CHILDREN:-4}"
export BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES="${BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES:-128}"
export BATS_CONTAINER_HEAP_PERCENT="${BATS_CONTAINER_HEAP_PERCENT:-0.80}"

export BATS_STORAGE_SERVICE_NAME="mysql"

export BATS_PHP_SCRIPTS_VOLUME_NAME=${BATS_PHP_SCRIPTS_VOLUME_NAME:-php_scripts}
export BATS_PHP_SOCKET_VOLUME_NAME=${BATS_PHP_SOCKET_VOLUME_NAME:-php_socket}
export BATS_SOURCES_VOLUME_NAME=${BATS_SOURCES_VOLUME_NAME:-php_sources}
export BATS_NGINX_CONFIG_VOLUME_NAME=${BATS_NGINX_CONFIG_VOLUME_NAME:-nginx_config}

export BATS_PHP_DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-docker.io/elasticms/base-php:8.0-fpm}"

export BATS_VARNISH_ENABLED=${BATS_VARNISH_ENABLED:-"false"}

export BATS_UID=$(id -u)

@test "[$TEST_FILE] Create Docker external volumes (local)" {
  command podman volume create -d local ${BATS_PHP_SCRIPTS_VOLUME_NAME}
  command podman volume create -d local ${BATS_PHP_SOCKET_VOLUME_NAME}
  command podman volume create -d local ${BATS_SOURCES_VOLUME_NAME}
  command podman volume create -d local ${BATS_NGINX_CONFIG_VOLUME_NAME}
}

@test "[$TEST_FILE] Loading Nginx config files in Docker Volume" {

  run provision-docker-volume-with-podman "${BATS_TEST_DIRNAME%/}/etc/nginx/conf.d/." "${BATS_NGINX_CONFIG_VOLUME_NAME}" "/"
  assert_output -l -r 'LOADING OK'

}

@test "[$TEST_FILE] Loading source files in Docker Volume" {

  run provision-docker-volume-with-podman "${BATS_TEST_DIRNAME%/}/src/." "${BATS_SOURCES_VOLUME_NAME}" "/"
  assert_output -l -r 'LOADING OK'

}

@test "[$TEST_FILE] Loading container-entrypoint.d scripts in Docker Volume" {

  run provision-docker-volume-with-podman "${BATS_TEST_DIRNAME%/}/bin/container-entrypoint.d/." "${BATS_PHP_SCRIPTS_VOLUME_NAME}" "/"
  assert_output -l -r 'LOADING OK'

}

@test "[$TEST_FILE] Starting LAMP stack services (nginx,mysql,php)" {
  command podman-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.php-fpm.yml up -d php-fpm mysql nginx
}

@test "[$TEST_FILE] Check for startup messages in containers logs" {
  podman_wait_for_log php-fpm 60 "NOTICE: fpm is running, pid 1"
  podman_wait_for_log php-fpm 60 "Running PHP script when Docker container start ..."
  podman_wait_for_log php-fpm 60 "Running Shell script when Docker container start ..."
  
  # Cannot test autoresizing with podman while limits in compose is not recognized
  # podman_wait_for_log php-fpm 60 "> pm.max_children=3"

  podman_wait_for_log php-fpm 60 "> php_value\[memory_limit\]=128M"
  podman_wait_for_log mysql 60 "Starting MySQL"
  podman_wait_for_healthy mysql 120
}

@test "[$TEST_FILE] Check for PHP Info page response code 200" {
  retry 12 5 curl_podman_container nginx :9000/phpinfo.php -H "Host: localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Index page response code 200" {
  retry 12 5 curl_podman_container nginx :9000/index.php -H "Host: localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Index page response message" {
  retry 12 5 curl_podman_container nginx :9000/index.php -H "Host: localhost" -s 
  assert_output -l -r "Base image - Default index.php page"
}

@test "[$TEST_FILE] Check for MySQL Connection CheckUp response code 200" {
  retry 12 5 curl_podman_container nginx :9000/check-mysql.php -H "Host: localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for MySQL Connection CheckUp response message" {
  retry 12 5 curl_podman_container nginx :9000/check-mysql.php -H "Host: localhost" -s 
  assert_output -l -r "Check MySQL Connection Done."
}

# Cannot test autoresizing with podman while limits and re-read environment variable in compose is not working
# 
# @test "[$TEST_FILE] Stop PHP-FPM test containers" {
#   command podman-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.php-fpm.yml stop php-fpm
# }
# 
# @test "[$TEST_FILE] Re-Start PHP-FPM test containers without PHP-FPM Auto-Sizing" {
#   export BATS_PHP_FPM_MAX_CHILDREN_AUTO_RESIZING=false
#   export BATS_PHP_FPM_MAX_CHILDREN=40
#   export BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES=16
#   run podman-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.php-fpm.yml up -d --force-recreate php-fpm
# }
# 
# @test "[$TEST_FILE] Check for startup messages in containers logs 2" {
#   podman_wait_for_log php-fpm 60 "> pm.max_children=40"
#   podman_wait_for_log php-fpm 60 "> php_value\[memory_limit\]=16M"
# }
#
# @test "[$TEST_FILE] Stop PHP-FPM test containers without PHP-FPM Auto-Sizing" {
#   command podman-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.php-fpm.yml stop php-fpm
# }
# 
# @test "[$TEST_FILE] Re-Start PHP-FPM test containers with PHP-FPM Auto-Sizing" {
#   export BATS_PHP_FPM_MAX_CHILDREN_AUTO_RESIZING=true
#   export BATS_PHP_FPM_MAX_CHILDREN=40
#   export BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES=16
#   command podman-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.php-fpm.yml up -d php-fpm
# }
# 
# @test "[$TEST_FILE] Check for startup messages in containers logs 3" {
#   podman_wait_for_log php-fpm 60 "> pm.max_children=26"
#   podman_wait_for_log php-fpm 60 "> php_value\[memory_limit\]=16M"
# }

@test "[$TEST_FILE] Stop all and delete test containers" {
  command podman-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.php-fpm.yml down -v
}

@test "[$TEST_FILE] Cleanup Docker external volumes (local)" {
  command podman volume rm ${BATS_PHP_SCRIPTS_VOLUME_NAME}
  command podman volume rm ${BATS_PHP_SOCKET_VOLUME_NAME}
  command podman volume rm ${BATS_SOURCES_VOLUME_NAME}
  command podman volume rm ${BATS_NGINX_CONFIG_VOLUME_NAME}
}