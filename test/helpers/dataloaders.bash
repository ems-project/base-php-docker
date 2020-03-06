function init_clair_local_scanner_config_volume {

  local -r _volume_name=$1
  local -r _filename=$2

  local -r _copy_status=0

  if [ -f ${_filename} ]; then

    docker container create --name dummy -v $_volume_name:/configs alpine:latest

    if [ ! "$?" -eq 0 ]; then
      _copy_status=1
    fi

    run docker cp -a ${_filename} dummy:/configs/

    if [ ! "$?" -eq 0 ]; then
      _copy_status=1
    fi

    docker rm dummy

    if [ ! "$?" -eq 0 ]; then
      _copy_status=1
    fi

  fi

  if [ "$_copy_status" -eq 0 ]; then
    echo "FS-VOLUME CLAIR-LOCAL-SCANNER CONFIG COPY OK"
    return 0
  else
    echo "FS-VOLUME CLAIR-LOCAL-SCANNER CONFIG COPY KO"
    false
  fi

}

function init_volume {

  local -r _volume_name=$1
  local -r _filename=$2

  local -r _copy_status=0

  if [ -f ${_filename} ]; then

    docker container create --name dummy -v $_volume_name:/tmp alpine:latest

    if [ ! "$?" -eq 0 ]; then
      _copy_status=1
    fi

    run docker cp -a ${_filename} dummy:/tmp

    if [ ! "$?" -eq 0 ]; then
      _copy_status=1
    fi

    docker rm dummy

    if [ ! "$?" -eq 0 ]; then
      _copy_status=1
    fi

  fi

  if [ "$_copy_status" -eq 0 ]; then
    echo "FS-VOLUME COPY OK"
    return 0
  else
    echo "FS-VOLUME COPY KO"
    false
  fi

}
