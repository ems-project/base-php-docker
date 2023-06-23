function configure_database {
  local -r _container_name=${1}

  local -r _DB_DRIVER=${2}
  local -r _DB_ROOT_USER=${3}
  local -r _DB_ROOT_PASSWORD=${4}
  local -r _DB_ROOT_NAME=${5}

  local -r _DB_PORT=${6}
  local -r _DB_HOST=${7}
  local -r _DB_USER=${8}
  local -r _DB_PASSWORD=${9}
  local -r _DB_NAME=${10}

  if [ ${_DB_DRIVER} = mysql ] ; then
    configure_mysql ${_container_name} ${_DB_ROOT_USER} ${_DB_ROOT_PASSWORD} ${_DB_ROOT_NAME} ${_DB_PORT} ${_DB_HOST} ${_DB_USER} ${_DB_PASSWORD} ${_DB_NAME}
  elif [ ${_DB_DRIVER} = pgsql ] ; then
    configure_pgsql ${_container_name} ${_DB_ROOT_USER} ${_DB_ROOT_PASSWORD} ${_DB_ROOT_NAME} ${_DB_PORT} ${_DB_HOST} ${_DB_USER} ${_DB_PASSWORD} ${_DB_NAME}
  else
    echo "Driver ${_DB_DRIVER} not supported"
    return -1
  fi;

}

function configure_mysql {
  local -r _container_name=${1}

  local -r _DB_ROOT_USER=${2}
  local -r _DB_ROOT_PASSWORD=${3}
  local -r _DB_ROOT_NAME=${4}

  local -r _DB_PORT=${5}
  local -r _DB_HOST=${6}
  local -r _DB_USER=${7}
  local -r _DB_PASSWORD=${8}
  local -r _DB_NAME=${9}

  run ${BATS_CONTAINER_ENGINE} exec ${_container_name} sh -c "mysql -u${_DB_ROOT_USER} -p${_DB_ROOT_PASSWORD} -vvv -e \"CREATE DATABASE ${_DB_NAME};\""
  assert_output -l -r "Query OK, .* affected \(.*\)"

  run ${BATS_CONTAINER_ENGINE} exec ${_container_name} sh -c "mysql -u${_DB_ROOT_USER} -p${_DB_ROOT_PASSWORD} -vvv -e \"CREATE USER '${_DB_USER}'@'%' IDENTIFIED BY '${_DB_PASSWORD}';\""
  assert_output -l -r "Query OK, .* affected \(.*\)"

  run ${BATS_CONTAINER_ENGINE} exec ${_container_name} sh -c "mysql -u${_DB_ROOT_USER} -p${_DB_ROOT_PASSWORD} -vvv -e \"GRANT ALL PRIVILEGES ON ${_DB_NAME} . * TO '${_DB_USER}'@'%';\""
  assert_output -l -r "Query OK, .* affected \(.*\)"

  run ${BATS_CONTAINER_ENGINE} exec ${_container_name} sh -c "mysql -u${_DB_ROOT_USER} -p${_DB_ROOT_PASSWORD} -vvv -e \"FLUSH PRIVILEGES;\""
  assert_output -l -r "Query OK, .* affected \(.*\)"
  
}

function configure_pgsql {
  local -r _container_name=${1}

  local -r _DB_ROOT_USER=${2}
  local -r _DB_ROOT_PASSWORD=${3}
  local -r _DB_ROOT_NAME=${4}

  local -r _DB_PORT=${5}
  local -r _DB_HOST=${6}
  local -r _DB_USER=${7}
  local -r _DB_PASSWORD=${8}
  local -r _DB_NAME=${9}

  run ${BATS_CONTAINER_ENGINE} exec ${_container_name} sh -c "PGHOST=${_DB_HOST} PGPORT=${_DB_PORT} PGDATABASE=${_DB_ROOT_NAME} PGUSER=${_DB_ROOT_USER} PGPASSWORD=${_DB_ROOT_PASSWORD} psql --command=\"CREATE USER ${_DB_USER} WITH PASSWORD '${_DB_PASSWORD}';\""
  assert_output -l -r "CREATE ROLE"
  
  run ${BATS_CONTAINER_ENGINE} exec ${_container_name} sh -c "PGHOST=${_DB_HOST} PGPORT=${_DB_PORT} PGDATABASE=${_DB_ROOT_NAME} PGUSER=${_DB_ROOT_USER} PGPASSWORD=${_DB_ROOT_PASSWORD} psql --command=\"CREATE DATABASE ${_DB_NAME} WITH OWNER ${_DB_USER};\""
  assert_output -l -r "CREATE DATABASE"

}

function copy_to_s3bucket {

  local -r _filename=$1
  local -r _bucket=$2
  local -r _endpoint=$3

  local -r _basename=$(basename $_filename)
  local -r _name=${_basename%.*}
  local -r _relative=${_filename#"${BATS_TEST_DIRNAME}/"}

  local -r _copy_status=0

  run aws s3 cp ${_filename} s3://${_bucket%/}/ --endpoint-url ${_endpoint}
  assert_output -l -r ".*upload: test/${_relative} to s3://${_bucket%/}/${_basename}.*"

}

function provision-docker-volume {

  local -r CONTENT_PATH=${1}
  local -r VOLUME_NAME=${2}
  local -r VOLUME_PATH=${3}

  local STATUS=0

  ${BATS_CONTAINER_ENGINE} container create --name dummy -v ${VOLUME_NAME}:${VOLUME_PATH} alpine:latest

  if [ $? -eq 0 ]; then
    STATUS=0
  else
    STATUS=1
  fi

  ${BATS_CONTAINER_ENGINE} cp ${CONTENT_PATH} dummy:${VOLUME_PATH}

  if [ $? -eq 0 ]; then
    STATUS=0
  else
    STATUS=1
  fi

  ${BATS_CONTAINER_ENGINE} rm dummy
    
  if [ $? -eq 0 ]; then
    STATUS=0
  else
    STATUS=1
  fi

  if [ $STATUS -eq 0 ]; then
    echo "LOADING OK"
    return 0
  else
    echo "LOADING KO"
    false
  fi

}