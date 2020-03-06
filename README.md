# Base php-fpm Docker image [![Build Status](https://travis-ci.org/elasticms/docker-php-fpm.svg?branch=master)](https://travis-ci.org/elasticms/docker-php-fpm)

Docker base image is the basic image on which you add layers (which are basically filesystem changes) and create a final image containing your App.  

## Features

Use [Official PHP Docker image](https://hub.docker.com/_/php) as parent.  
Run container as non-privileged.  
Container Entrypoint hooks available.
