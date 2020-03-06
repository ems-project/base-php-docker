# Test if requirements are met
(
	type docker &>/dev/null || ( echo "docker is not available"; exit 1 )
)>&2

TEST_FILE=$(basename $BATS_TEST_FILENAME .bats)

# stop all containers with the "bats-type" label (matching the optionally supplied value)
#
# $1 optional label value
function stop_bats_containers {
	docker-compose stop $1
}

# delete all containers
docker_cleanup() {
	docker-compose down -v
}

# Send a HTTP request to container $1 for path $2 and
# Additional curl options can be passed as $@
#
# $1 container name
# $2 HTTP path to query
# $@ additional options to pass to the curl command
function curl_container {
	local -r container=$1
	local -r path=$2
	shift 2
	docker run --rm --net=docker_default --label bats-type="curl" appropriate/curl --silent \
		--connect-timeout 5 \
		--max-time 20 \
		--retry 4 --retry-delay 5 \
		"$@" \
		http://$(docker_ip $container)${path}
}

# Retry a command $1 times until it succeeds. Wait $2 seconds between retries.
function retry {
    local attempts=$1
    shift
    local delay=$1
    shift
    local i

    for ((i=0; i < attempts; i++)); do
        run "$@"
        if [ "$status" -eq 0 ]; then
            echo "$output"
            return 0
        fi
        sleep $delay
    done

    echo "Command \"$@\" failed $attempts times. Status: $status. Output: $output" >&2
    false
}

function configure_ems_storage_volume {
    
  local -r _volume_name=$1

  docker container create --name dummy -v $_volume_name:/var/lib/ems alpine:latest
  if [ ! "$?" -eq 0 ]; then
    echo "CONFIGURATION KO"
    false
  fi

  mkdir -p /tmp/configure_ems_storage_volume/uploads
  mkdir -p /tmp/configure_ems_storage_volume/dumps
  
  touch /tmp/configure_ems_storage_volume/uploads/.empty
  touch /tmp/configure_ems_storage_volume/dumps/.empty

  run docker cp /tmp/configure_ems_storage_volume/. dummy:/var/lib/ems/

  if [ ! "$?" -eq 0 ]; then
    echo "CONFIGURATION KO"
    false
  fi

  docker rm dummy

  if [ ! "$?" -eq 0 ]; then
    echo "CONFIGURATION KO"
    false
  fi

  run rm -Rf /tmp/configure_ems_storage_volume

  if [ ! "$?" -eq 0 ]; then
    echo "CONFIGURATION KO"
    false
  fi

  echo "CONFIGURATION OK"
  return 0

}