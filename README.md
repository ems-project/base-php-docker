# Base Docker image [![Docker Build](https://github.com/ems-project/docker-php-fpm/actions/workflows/docker-build.yml/badge.svg?branch=7.4)](https://github.com/ems-project/docker-php-fpm/actions/workflows/docker-build.yml)

Docker base image is the basic image on which you add layers (which are basically filesystem changes) and create a final image containing your App.  

## Features

Use [Official PHP Docker image](https://hub.docker.com/_/php) as parent.  
Use [Supervisord] as manager for Webserver **and** PHP-FPM.  Supervisord is therefore process 1.  
Run container as non-privileged.  
Container Entrypoint hooks available.  

Installation of [Nginx](https://pkgs.alpinelinux.org/package/v3.16/main/x86_64/nginx).  
Installation of [Apache 2.4](https://pkgs.alpinelinux.org/package/v3.16/main/x86_64/apache2).  
Installation of [Varnish](https://pkgs.alpinelinux.org/package/v3.16/main/x86_64/varnish).  

## Build

```
set -a
source .build.env
set +a

docker build --build-arg VERSION_ARG=${PHP_VERSION} \
             --build-arg RELEASE_ARG=snapshot \
             --build-arg BUILD_DATE_ARG="" \
             --build-arg VCS_REF_ARG="" \
             --target php-fpm-prod \
             -t ${PHPFPM_PRD_DOCKER_IMAGE_NAME}:latest .

docker build --build-arg VERSION_ARG=${PHP_VERSION} \
             --build-arg RELEASE_ARG=snapshot \
             --build-arg BUILD_DATE_ARG="" \
             --build-arg VCS_REF_ARG="" \
             --target php-fpm-dev \
             -t ${PHPFPM_DEV_DOCKER_IMAGE_NAME}:latest .

docker build --build-arg VERSION_ARG=${PHP_VERSION} \
             --build-arg RELEASE_ARG=snapshot \
             --build-arg BUILD_DATE_ARG="" \
             --build-arg VCS_REF_ARG="" \
             --target apache-prod \
             -t ${APACHE_PRD_DOCKER_IMAGE_NAME}:latest .

docker build --build-arg VERSION_ARG=${PHP_VERSION} \
             --build-arg RELEASE_ARG=snapshot \
             --build-arg BUILD_DATE_ARG="" \
             --build-arg VCS_REF_ARG="" \
             --target apache-dev \
             -t ${APACHE_DEV_DOCKER_IMAGE_NAME}:latest .

docker build --build-arg VERSION_ARG=${PHP_VERSION} \
             --build-arg RELEASE_ARG=snapshot \
             --build-arg BUILD_DATE_ARG="" \
             --build-arg VCS_REF_ARG="" \
             --target nginx-prod \
             -t ${NGINX_PRD_DOCKER_IMAGE_NAME}:latest .

docker build --build-arg VERSION_ARG=${PHP_VERSION} \
             --build-arg RELEASE_ARG=snapshot \
             --build-arg BUILD_DATE_ARG="" \
             --build-arg VCS_REF_ARG="" \
             --target nginx-prod \
             -t ${NGINX_DEV_DOCKER_IMAGE_NAME}:latest .
```

## Test 

```
set -a
source .build.env
set +a

bats test/tests.apache.bats
bats test/tests.nginx.bats
bats test/tests.php-fpm.bats
bats test/tests.varnish.bats
```


## PHP-FPM Configuration

You can change the amount of memory that PHP-FPM can use by changing / passing the environment variables ```PHP_FPM_MAX_CHILDREN``` and ```PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES```.  
These values can be overridden automatically by the startup script if a QoS memory limit is applied and detected in your container.  
However, this value can be reduced to a percentage by the configuration of the environment variable ```CONTAINER_HEAP_PERCENT``` (default: 80 %).  


| Name | Default Value | Description |
|-|-|-|
| ```PHP_FPM_MAX_CHILDREN_AUTO_RESIZING``` | ```true``` | Enable auto-resizing of PHP-FPM Pool Memory settings based on container size. |
| ```PHP_FPM_MAX_CHILDREN``` | ```40``` | The maximum number of child processes to be created. ([doc](https://www.php.net/manual/en/install.fpm.configuration.php)) |
| ```PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES``` | ```16``` | The maximum amount of memory in MB that a script is allowed to allocate. ([doc](https://www.php.net/manual/fr/ini.core.php#ini.memory-limit)) |
| ```CONTAINER_HEAP_PERCENT``` | ```0.80``` | Percentage of total memory allowed to use by PHP-FPM. |

## Varnish Configuration

| Name | Default Value | Description |
|-|-|-|
| ```VARNISH_ENABLED``` | ```false``` | Enable Varnish. Listen on ```6081``` for HTTP proto when Varnish is enabled. Management interface is available on ```6082```. |
| ```VARNISH_STORAGE_MALLOC_CUSTOM_SIZE``` | ```200M``` | Malloc is a memory based backend. Each object will be allocated from memory. If your system runs low on memory swap will be used. ([doc](https://varnish-cache.org/docs/trunk/users-guide/storage-backends.html#malloc)) |
| ```VARNISH_NCSA_LOG_FORMAT_CUSTOM``` | ```%%h %%l %%u %%t %%D \"%%r\" %%s %%b %%{Varnish:hitmiss}x \"%%{User-agent}i\"``` | The varnishncsa utility reads varnishd(1) shared memory logs and presents them in the Apache / NCSA “combined” log format. ([doc](https://varnish-cache.org/docs/trunk/reference/varnishncsa.html#format)) |
| ```VARNISH_TTL_CUSTOM``` | ```120``` | Specifies the default time to live (TTL) for cached objects. This is a shortcut for specifying the default_ttl run-time parameter. ([doc](https://varnish-cache.org/docs/trunk/reference/varnishd.html#tuning-options)) |
| ```VARNISH_MIN_THREADS_CUSTOM``` | ```5``` | The minimum number of worker threads in each pool. ([doc](https://varnish-cache.org/docs/trunk/reference/varnishd.html#thread-pool-min)) |
| ```VARNISH_MAX_THREADS_CUSTOM``` | ```1000``` | The maximum number of worker threads in each pool. ([doc](https://varnish-cache.org/docs/trunk/reference/varnishd.html#thread_pool_max)) |
| ```VARNISH_THREAD_TIMEOUT_CUSTOM``` | ```120``` | Thread idle threshold. ([doc](https://varnish-cache.org/docs/trunk/reference/varnishd.html#thread-pool-timeout)) |
| ```VARNISH_VCL_CONF_CUSTOM``` | ```/etc/varnish/default.vcl``` | Use the specified file location as VCL configuration instead of the builtin default.  You must provide this file or generate it at container startup.  ([doc](https://varnish-cache.org/docs/trunk/reference/vcl.html#vcl-7)) |
