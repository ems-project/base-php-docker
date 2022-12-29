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

# Build

```sh
make build[-fpm|-apache|-nginx|-all][-dev] PHP_VERSION=<PHP Version you want to build> [ DOCKER_IMAGE_NAME=<PHP Docker Image Name you want to build> ]
```

## Example building __fpm__ variant __prd__ Docker image

```sh
make build-fpm PHP_VERSION=7.4.33
```

__Provide docker image__ : `docker.io/elasticms/base-php:7.4.33-fpm-prd`

## Example building __fpm__ variant __dev__ Docker image

```sh
make build-fpm-dev PHP_VERSION=7.4.33
```

__Provide docker image__ : `docker.io/elasticms/base-php:7.4.33-fpm-dev`

## Example building __nginx__ variant __dev__ Docker image

```sh
make build-nginx-dev PHP_VERSION=7.4.33
```

__Provide docker image__ : `docker.io/elasticms/base-php:7.4.33-nginx-dev`

## Example building __all__ variants Docker image

```sh
make build-all PHP_VERSION=7.4.33
```

__Provide docker images__ : 

- `docker.io/elasticms/base-php:7.4.33-fpm-prd`
- `docker.io/elasticms/base-php:7.4.33-fpm-dev`
- `docker.io/elasticms/base-php:7.4.33-apache-prd`
- `docker.io/elasticms/base-php:7.4.33-apache-dev`
- `docker.io/elasticms/base-php:7.4.33-nginx-prd`
- `docker.io/elasticms/base-php:7.4.33-nginx-dev`

# Test

```sh
make test[-fpm|-apache|-nginx|-all][-dev] PHP_VERSION=<PHP Version you want to test>
```

## Example testing of __prd__ builded docker image

```sh
make test PHP_VERSION=7.4.33
```

## Example testing of __dev__ builded docker image

```sh
make test-dev PHP_VERSION=7.4.33
```

# Releases

Releases are done via GitHub actions and uploaded on Docker Hub.

# Supported tags and respective Dockerfile links

- [`7.4.x-fpm`, `7.4-fpm`, `7-fpm`, `7.4.x-fpm-prd`, `7.4-fpm-prd`, `7-fpm-prd`, `7.4.y-fpm-dev`, `7.4-fpm-dev`, `7-fpm-dev`](Dockerfile)
- [`7.4.x-apache`, `7.4-apache`, `7-apache`, `7.4.x-apache-prd`, `7.4-apache-prd`, `7-apache-prd`, `7.4.y-apache-dev`, `7.4-apache-dev`, `7-apache-dev`](Dockerfile)
- [`7.4.x-nginx`, `7.4-nginx`, `7-nginx`, `7.4.x-nginx-prd`, `7.4-nginx-prd`, `7-nginx-prd`, `7.4.y-nginx-dev`, `7.4-nginx-dev`, `7-nginx-dev`](Dockerfile)

# Image Variants

The `docker.io/elasticms/base-php` images come in many flavors, each designed for a specific use case.

## `docker.io/elasticms/base-php:<version>-fpm[-prd]`  

This image is based and use the official PHP Docker Hub image [`docker.io/php:7.4.x-fpm-alpine3.16`](https://hub.docker.com/_/php) as parent.  
It is configured and configurable to support any PHP application.  
It use the default php.ini-production configuration files and Supervisor to help automate the Docker image.  

- Supervisor
- Varnish
- PHP Extensions :
  - Redis
  - APCu
- AWS CLI

## `docker.io/elasticms/base-php:<version>-apache[-prd]`  

This variant contains Debian's Apache httpd in conjunction with PHP-FPM and uses [Supervisord] as manager for Apache **and** PHP-FPM.  

## `docker.io/elasticms/base-php:<version>-nginx[-prd]`  

This variant contains Nginx Webserver in conjunction with PHP-FPM and uses [Supervisord] as manager for Nginx **and** PHP-FPM.  

## `docker.io/elasticms/base-php:<version>-dev`

This image ship and use the default php.ini-development configuration files.  
It is strongly recommended to not use this image in production environments!  

- Composer
- xdebug

## **Warning** : The following images are deprecated and are no longer maintained.  They will be removed soon, please update your dockerfiles and docker-dompose.yml files 

> [DEPRECATED] - WIL BE REMOVED SOON  
> [DEPRECATED] `docker.io/elasticms/base-php-fpm:<version>`  
> [DEPRECATED] `docker.io/elasticms/base-php-dev:<version>`  
> [DEPRECATED] `docker.io/elasticms/base-apache-fpm:<version>`  
> [DEPRECATED] `docker.io/elasticms/base-apache-dev:<version>`  
> [DEPRECATED] `docker.io/elasticms/base-nginx-fpm:<version>`  
> [DEPRECATED] `docker.io/elasticms/base-nginx-dev:<version>`  
> [DEPRECATED] - WIL BE REMOVED SOON  

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
