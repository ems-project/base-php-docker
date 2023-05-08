## functions to help deal with docker

# Removes container $1
function podman_clean {
  podman kill $1 &>/dev/null ||:
  sleep .25s
  podman rm -vf $1 &>/dev/null ||:
  sleep .25s
}

# get the ip of podman container $1
function podman_ip {
  podman inspect --format '{{ .NetworkSettings.Networks.docker_default.IPAddress }}' $1
}

# get the id of podman container $1
function podman_id {
  podman inspect --format '{{ .ID }}' $1
}

# get the running state of container $1
# → true/false
# fails if the container does not exist
function podman_running_state {
  podman inspect --format '{{ .State.Running }}' $1
}

# get the health state of container $1
# fails if the container does not exist
function podman_health_state() {
  podman inspect --format '{{ .State.Health.Status }}' $1
}

# get the podman container $1 PID
function podman_pid {
  podman inspect --format {{.State.Pid}} $1
}

# asserts state from container $1 contains healthy
function podman_assert_healthy {
  local -r container=$1
  shift
  podman_health_state $container
  assert_output -l "healthy"
}

# asserts logs from container $1 contains $2
function podman_assert_log {
  local -r container=$1
  shift
  run podman logs $container
  #assert_output -p "$*"
  assert_output -r "$*"
}

# asserts command $2 output from container $1 contains $3
function podman_assert_command {
  local -r container=$1
  local -r command_to_exec=$2
  shift 2
  run podman exec $container $command_to_exec
  #assert_output -p "$*"
  assert_output -r "$*"
}

# wait for a container to produce a given text in its log
# $1 container
# $2 timeout in second
# $* text to wait for
function podman_wait_for_log {
  local -r container=$1
  local -ir timeout_sec=$2
  shift 2
  retry $(( $timeout_sec * 2 )) .5s podman_assert_log $container "$*"
}

# wait for a container healthy state
# $1 container
# $2 timeout in second
function podman_wait_for_healthy {
  local -r container=$1
  local -ir timeout_sec=$2
  shift 2
  retry $(( $timeout_sec * 2 )) .5s podman_assert_healthy $container
}

function init_volume {

  local -r _volume_name=$1
  local -r _filename=$2

  local -r _copy_status=0

  if [ -f ${_filename} ]; then

    podman container create --name dummy -v $_volume_name:/tmp alpine:latest

    if [ ! "$?" -eq 0 ]; then
      _copy_status=1
    fi

    run podman cp -a ${_filename} dummy:/tmp

    if [ ! "$?" -eq 0 ]; then
      _copy_status=1
    fi

    podman rm dummy

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