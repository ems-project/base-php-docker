# Base Docker image ![Continuous Docker Image Build](https://github.com/ems-project/docker-php-fpm/workflows/Continuous%20Docker%20Image%20Build/badge.svg)

Docker base image is the basic image on which you add layers (which are basically filesystem changes) and create a final image containing your App.  

## Features

Use [Official PHP Docker image](https://hub.docker.com/_/php) as parent.  
Use [Supervisord] as manager for Webserver **and** PHP-FPM.  Supervisord is therefore process 1.  
Run container as non-privileged.  
Container Entrypoint hooks available.  

Installation of [Nginx](https://pkgs.alpinelinux.org/package/v3.12/main/x86_64/nginx).  
Installation of [Apache 2.4](https://pkgs.alpinelinux.org/package/v3.12/main/x86_64/apache2).  

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