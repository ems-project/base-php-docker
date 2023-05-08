function provision-docker-volume {

  local -r CONTENT_PATH=${1}
  local -r VOLUME_NAME=${2}
  local -r VOLUME_PATH=${3}

  local STATUS=0

  docker container create --name dummy -v ${VOLUME_NAME}:${VOLUME_PATH} alpine:latest

  if [ $? -eq 0 ]; then
    STATUS=0
  else
    STATUS=1
  fi

  docker cp ${CONTENT_PATH} dummy:${VOLUME_PATH}

  if [ $? -eq 0 ]; then
    STATUS=0
  else
    STATUS=1
  fi

  docker rm dummy
    
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

function provision-docker-volume-with-podman {

  local -r CONTENT_PATH=${1}
  local -r VOLUME_NAME=${2}
  local -r VOLUME_PATH=${3}

  local STATUS=0

  podman container create --name dummy -v ${VOLUME_NAME}:${VOLUME_PATH} alpine:latest

  if [ $? -eq 0 ]; then
    STATUS=0
  else
    STATUS=1
  fi

  podman cp ${CONTENT_PATH} dummy:${VOLUME_PATH}

  if [ $? -eq 0 ]; then
    STATUS=0
  else
    STATUS=1
  fi

  podman rm dummy
    
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