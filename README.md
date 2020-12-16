# Base Docker image ![Continuous Docker Image Build](https://github.com/ems-project/docker-php-fpm/workflows/Continuous%20Docker%20Image%20Build/badge.svg)

Docker base image is the basic image on which you add layers (which are basically filesystem changes) and create a final image containing your App.  

## Features

Use [Official PHP Docker image](https://hub.docker.com/_/php) as parent.  
Use [Supervisord] as manager for Webserver **and** PHP-FPM.  Supervisord is therefore process 1.  
Run container as non-privileged.  
Container Entrypoint hooks available.  

Installation of [Nginx](https://pkgs.alpinelinux.org/package/v3.12/main/x86_64/nginx).  
Installation of [Apache 2.4](https://pkgs.alpinelinux.org/package/v3.12/main/x86_64/apache2).  
