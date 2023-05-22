# Base Docker image [![Docker Build](https://github.com/ems-project/base-php-docker/actions/workflows/docker-build.yml/badge.svg?branch=8.1)](https://github.com/ems-project/base-php-docker/actions/workflows/docker-build-v2.yml)

Docker base image is the basic image on which you add layers (which are basically filesystem changes) and create a final image containing your App.  

# Features

Use [Official PHP Docker image](https://hub.docker.com/_/php) as parent.  
Use [Supervisor](http://supervisord.org/) as manager for Webserver **and** PHP-FPM.  Supervisord is therefore process 1.  
Run container as non-privileged.  
Container Entrypoint hooks available.  

- Installation of [Nginx](https://pkgs.alpinelinux.org/package/v3.17/main/x86_64/nginx).  
- Installation of [Apache 2.4](https://pkgs.alpinelinux.org/package/v3.17/main/x86_64/apache2).  
- Installation of [Varnish](https://pkgs.alpinelinux.org/package/v3.17/main/x86_64/varnish).  

# Build

## Prerequisite

You must install `make`, `m4`.

## Generate Dockerfile

```sh
make Dockefile
```

## Build locally Docker images

```sh
make build[-fpm|-apache|-nginx|-cli|-all][-dev] [ PHP_VERSION=<PHP Version you want to build> ] \
                                                [ DOCKER_IMAGE_NAME=<PHP Docker Image Name you want to build> ] \
                                                [ NODE_VERSION=<NodeJS Version> ] \
                                                [ COMPOSER_VERSION=<Composer Version> ] \
                                                [ AWS_CLI_VERSION=<AWS CLI Version> ] \
                                                [ PHP_EXT_REDIS_VERSION=<PHP Extension Redis Version> ] \
                                                [ PHP_EXT_APCU_VERSION=<PHP Extension APCu Version> ] \
                                                [ PHP_EXT_XDEBUG_VERSION=<PHP Extension XDebug Version> ]
```

Default value of Docker build arguments is grabbed from the [.build.env](.build.env) file if it is present, otherwise Docker build will use the default values available in the Dockerfile.  Default values can be also overridden via the make command line.  

## Example building __fpm__ variant __prd__ Docker image

```sh
make build-fpm PHP_VERSION=8.1.14
```

__Provide docker image__ : `docker.io/elasticms/base-php:8.1.14-fpm-prd`

```sh
make build-fpm PHP_VERSION=8.1.14 DOCKER_IMAGE_NAME=docker.io/lambdauser/mybasephpimage
```

__Provide docker image__ : `docker.io/lambdauser/mybasephpimage:8.1.14-fpm-prd`

## Example building __fpm__ variant __dev__ Docker image

```sh
make build-fpm-dev PHP_VERSION=8.1.14
```

__Provide docker image__ : `docker.io/elasticms/base-php:8.1.14-fpm-dev`

## Example building __nginx__ variant __dev__ Docker image

```sh
make build-nginx-dev PHP_VERSION=8.1.14
```

__Provide docker image__ : `docker.io/elasticms/base-php:8.1.14-nginx-dev`

## Example building __all__ variants Docker image

```sh
make build-all PHP_VERSION=8.1.14
```

__Provide docker images__ : 

- `docker.io/elasticms/base-php:8.1.14-fpm-prd`
- `docker.io/elasticms/base-php:8.1.14-fpm-dev`
- `docker.io/elasticms/base-php:8.1.14-apache-prd`
- `docker.io/elasticms/base-php:8.1.14-apache-dev`
- `docker.io/elasticms/base-php:8.1.14-nginx-prd`
- `docker.io/elasticms/base-php:8.1.14-nginx-dev`
- `docker.io/elasticms/base-php:8.1.14-cli-prd`
- `docker.io/elasticms/base-php:8.1.14-cli-dev`
# Test

## Prerequisite

You must install `bats`, `docker`, `docker-compose` and create a local network called `docker_default`.  

## Test Docker images builded locally

```sh
make test[-fpm|-apache|-nginx|-cli|-all][-dev] PHP_VERSION=<PHP Version you want to test>
```

## Example testing of __prd__ builded docker image

```sh
make test PHP_VERSION=8.1.14
```

## Example testing of __dev__ builded docker image

```sh
make test-dev PHP_VERSION=8.1.14
```

# Releases

Releases are done via GitHub actions and uploaded on Docker Hub.

# Supported tags and respective Dockerfile links

- [`8.1.x-fpm`, `8.1-fpm`, `8.1.x-fpm-prd`, `8.1-fpm-prd`, `8.1.y-fpm-dev`, `8.1-fpm-dev`](Dockerfiles/Dockerfile.in)
- [`8.1.x-apache`, `8.1-apache`, `8.1.x-apache-prd`, `8.1-apache-prd`, `8.1.y-apache-dev`, `8.1-apache-dev`](Dockerfiles/Dockerfile.in)
- [`8.1.x-nginx`, `8.1-nginx`, `8.1.x-nginx-prd`, `8.1-nginx-prd`, `8.1.y-nginx-dev`, `8.1-nginx-dev`](Dockerfiles/Dockerfile.in)
- [`8.1.x-cli`, `8.1-cli`, `8.1.x-cli-prd`, `8.1-cli-prd`, `8.1.y-cli-dev`, `8.1-cli-dev`](Dockerfiles/Dockerfile.in)

# Image Variants

The `docker.io/elasticms/base-php` images come in many flavors, each designed for a specific use case.

## `docker.io/elasticms/base-php:<version>-fpm[-prd]`  

This image is based and use the official PHP Docker Hub image [`docker.io/php:8.1.x-fpm-alpine3.16`](https://hub.docker.com/_/php) as parent.  
It is configured and configurable to support any PHP application.  
It use the default php.ini-production configuration files and Supervisor to help automate the Docker image.  

- [Supervisor](http://supervisord.org/)
- [Varnish](https://varnish-cache.org/)
- PHP Extensions :
  - [Redis](https://pecl.php.net/package/redis)
  - [APCu](https://pecl.php.net/package/apcu)
- [AWS CLI](https://github.com/aws/aws-cli)

## `docker.io/elasticms/base-php:<version>-dev`

This image use `base-php:<version>-fpm-prd` (see above) as parent layer.  
It use the default php.ini-development configuration files.  
It is strongly recommended to not use this image in production environments!  

In addition to the parent layer, this variant include install :

- [Composer](https://github.com/composer/composer)
- PHP Extension : [xdebug](https://xdebug.org/)
- [NodeJS](https://hub.docker.com/_/node)

## `docker.io/elasticms/base-php:<version>-apache[-prd]`  

This image use `base-php:<version>-fpm-prd` (see above) as parent layer.  
This variant contains Apache httpd in conjunction with PHP-FPM and uses supervisor as manager for Apache **and** PHP-FPM.  

## `docker.io/elasticms/base-php:<version>-nginx[-prd]`  

This image use `base-php:<version>-fpm-prd` (see above) as parent layer.  
This variant contains Nginx Webserver in conjunction with PHP-FPM and uses supervisor as manager for Nginx **and** PHP-FPM.  

## `docker.io/elasticms/base-php:<version>-cli[-prd]`  

This variant contains the PHP CLI tool with default mods.  In addition we install and configure :

- PHP Extensions :
  - [Redis](https://pecl.php.net/package/redis)
  - [APCu](https://pecl.php.net/package/apcu)
- [AWS CLI](https://github.com/aws/aws-cli)

## `docker.io/elasticms/base-php:<version>-apache-dev`

This image use `base-php:<version>-fpm-dev` (see above) as parent layer.  
This variant contains Apache Webserver in conjunction with PHP-FPM and uses supervisor as manager for Apache **and** PHP-FPM.  
It is strongly recommended to not use this image in production environments!  

## `docker.io/elasticms/base-php:<version>-nginx-dev`

This image use `base-php:<version>-fpm-dev` (see above) as parent layer.  
This variant contains Nginx Webserver in conjunction with PHP-FPM and uses supervisor as manager for Nginx **and** PHP-FPM.  
It is strongly recommended to not use this image in production environments!  

## `docker.io/elasticms/base-php:<version>-cli-dev`  

This image use `base-php:<version>-cli-prd` (see above) as parent layer.  

In addition to the parent layer, this variant include install :

- [Composer](https://github.com/composer/composer)
- PHP Extension : [xdebug](https://xdebug.org/)

## **Warning** : The following images are deprecated and are no longer maintained.  

> They will be removed soon, please update your dockerfiles and docker-compose.yml files ...  

| Deprecated Image Name | Replaced Image Name |
| -- | -- |
| `docker.io/elasticms/base-php-fpm:<version>` | `docker.io/elasticms/base-php:<version>-fpm[-prd]` |
| `docker.io/elasticms/base-php-dev:<version>` | `docker.io/elasticms/base-php:<version>-fpm-dev` |
| `docker.io/elasticms/base-apache-fpm:<version>` | `docker.io/elasticms/base-php:<version>-apache[-prd]` |
| `docker.io/elasticms/base-apache-dev:<version>` | `docker.io/elasticms/base-php:<version>-apache-dev` |
| `docker.io/elasticms/base-nginx-fpm:<version>` | `docker.io/elasticms/base-php:<version>-nginx[-prd]` |
| `docker.io/elasticms/base-nginx-dev:<version>` | `docker.io/elasticms/base-php:<version>-nginx-dev` |
| `docker.io/elasticms/base-php-cli:<version>` | `docker.io/elasticms/base-php:<version>-cli[-prd]` |
| `docker.io/elasticms/base-php-cli-dev:<version>` | `docker.io/elasticms/base-php:<version>-cli-dev` |

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
