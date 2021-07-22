ARG VERSION_ARG

FROM php:${VERSION_ARG}-fpm-alpine3.14 AS php-fpm-prod

ARG VERSION_ARG
ARG RELEASE_ARG
ARG BUILD_DATE_ARG
ARG VCS_REF_ARG

LABEL eu.elasticms.base-php-fpm.build-date=$BUILD_DATE_ARG \
      eu.elasticms.base-php-fpm.name="" \
      eu.elasticms.base-php-fpm.description="" \
      eu.elasticms.base-php-fpm.url="https://hub.docker.com/repository/docker/elasticms/base-php-fpm" \
      eu.elasticms.base-php-fpm.vcs-ref=$VCS_REF_ARG \
      eu.elasticms.base-php-fpm.vcs-url="https://github.com/ems-project/docker-php-fpm" \
      eu.elasticms.base-php-fpm.vendor="sebastian.molle@gmail.com" \
      eu.elasticms.base-php-fpm.version="$VERSION_ARG" \
      eu.elasticms.base-php-fpm.release="$RELEASE_ARG" \
      eu.elasticms.base-php-fpm.schema-version="1.0" 

USER root

ENV MAIL_SMTP_SERVER="" \
    MAIL_FROM_DOMAIN="" \
    AWS_CLI_VERSION=1.16.207 \
    AWS_CLI_DOWNLOAD_URL="https://github.com/aws/aws-cli/archive" \
    PHP_FPM_MAX_CHILDREN=${PHP_FPM_MAX_CHILDREN:-5} \
    PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES=${PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES:-128} \
    CONTAINER_HEAP_PERCENT=${CONTAINER_HEAP_PERCENT:-0.80} \
    HOME=/home/default \
    PATH=/opt/bin:/usr/local/bin:/usr/bin:$PATH

COPY etc/php/ /usr/local/etc/
COPY etc/ssmtp/ /etc/ssmtp/
COPY bin/ /usr/local/bin/

RUN mkdir -p /home/default /opt/etc /opt/bin/container-entrypoint.d /opt/src /var/lock \
    && chmod +x /usr/local/bin/apk-list \
                /usr/local/bin/container-entrypoint \
                /usr/local/bin/wait-for-it \
    && echo "Install and Configure required extra PHP packages ..." \
    && apk add --update --no-cache --virtual .build-deps $PHPIZE_DEPS autoconf freetype-dev icu-dev \
                                                libjpeg-turbo-dev libpng-dev libwebp-dev libxpm-dev \
                                                libzip-dev openldap-dev pcre-dev gnupg git bzip2-dev \
                                                musl-libintl postgresql-dev libxml2-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j "$(nproc)" soap iconv bz2 fileinfo gettext intl pcntl pgsql \
                                            pdo_pgsql simplexml ldap gd ldap mysqli pdo_mysql \
                                            zip opcache bcmath exif \
    && pecl install APCu-5.1.19 \
    && pecl install redis-5.3.1 \
    && docker-php-ext-enable apcu redis \
    && runDeps="$( \
       scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
       | tr ',' '\n' \
       | sort -u \
       | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
       )" \
    && apk add --update --no-cache --virtual .ems-phpext-rundeps $runDeps \
    && apk add --update --upgrade --no-cache --virtual .ems-rundeps curl tzdata \
                                      bash tar gettext ssmtp postgresql-client postgresql-libs \
                                      libjpeg-turbo freetype libpng libwebp libxpm mailx coreutils \
                                      mysql-client jq wget icu-libs libxml2 python3 py3-pip \
    && mkdir -p /var/run/php-fpm \
    && cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && echo "Setup timezone ..." \
    && cp /usr/share/zoneinfo/Europe/Brussels /etc/localtime \
    && echo "Europe/Brussels" > /etc/timezone \
    && echo "Add non-privileged user ..." \
    && adduser -D -u 1001 -g default -s /sbin/nologin default \
    && echo "Configure OpCache ..." \
    && echo 'opcache.memory_consumption=128' > /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo 'opcache.interned_strings_buffer=8' >> /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo 'opcache.max_accelerated_files=4000' >> /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo 'opcache.revalidate_freq=2' >> /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo 'opcache.fast_shutdown=1' >> /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo "Download and install aws-cli ..." \
    && mkdir -p /tmp/aws-cli \
    && curl -sSfLk ${AWS_CLI_DOWNLOAD_URL}/${AWS_CLI_VERSION}.tar.gz | tar -xzC /tmp/aws-cli --strip-components=1 \
    && cd /tmp/aws-cli \
    && python3 setup.py install \
    && cd /opt && rm -Rf /tmp/aws-cli \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && chown -Rf 1001:0 /home/default /opt /etc/ssmtp /usr/local/etc /var/run/php-fpm /var/lock \
    && chmod -R ug+rw /home/default /opt /etc/ssmtp /usr/local/etc /var/run/php-fpm \
    && find /opt -type d -exec chmod ug+x {} \; \
    && find /var/lock -type d -exec chmod ug+x {} \; \
    && find /usr/local/etc -type d -exec chmod ug+x {} \; 

USER 1001

ENTRYPOINT ["container-entrypoint"]

HEALTHCHECK --start-period=10s --interval=1m --timeout=5s --retries=5 \
        CMD bash -c '[ -S /var/run/php-fpm/php-fpm.sock ]'

CMD ["php-fpm", "-F", "-R"]

FROM php-fpm-prod AS php-fpm-dev

USER root

RUN echo "Install and Configure required extra PHP packages ..." \
    && apk add --update --no-cache --virtual .build-deps $PHPIZE_DEPS autoconf \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && runDeps="$( \
       scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
       | tr ',' '\n' \
       | sort -u \
       | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
       )" \
    && apk add --no-cache --virtual .php-dev-phpext-rundeps $runDeps \
    && apk add --no-cache --virtual .php-dev-rundeps git npm \
    && apk del .build-deps \
    && echo "Configure Xdebug ..." \
    && echo '[xdebug]' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && echo 'xdebug.mode=debug' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && echo 'xdebug.start_with_request=yes' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && echo 'xdebug.client_port=9003' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && echo 'xdebug.client_host=host.docker.internal' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" \
    && rm -rf /var/cache/apk/* \
    && echo "Download and install Composer ..." \
    && curl -sSfLk https://getcomposer.org/installer -o /tmp/composer-setup.php \
    && curl -sSfLk https://composer.github.io/installer.sig -o /tmp/composer-setup.sig \
    && COMPOSER_INSTALLER_SHA384SUM=$(cat /tmp/composer-setup.sig) \
    && echo "$COMPOSER_INSTALLER_SHA384SUM /tmp/composer-setup.php" | sha384sum -c \
    && php /tmp/composer-setup.php --disable-tls --install-dir=/usr/local/bin \
    && rm /tmp/composer-setup.php /tmp/composer-setup.sig \
    && ln -s /usr/local/bin/composer.phar /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer.phar /usr/local/bin/composer \
    && mkdir /home/default/.composer \
    && chown 1001:0 /home/default/.composer \
    && chmod -R ug+rw /home/default/.composer \
    && echo "Install NPM ..." \
    && apk add --update --no-cache npm \
    && rm -rf /var/cache/apk/* /home/default/.composer \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && chown -Rf 1001:0 /home/default \
    && chmod -R ug+rw /home/default \
    && find /home/default -type d -exec chmod ug+x {} \; 

EXPOSE 9003

USER 1001

FROM php-fpm-prod AS apache-prod

USER root

COPY etc/apache2/ /etc/apache2/
COPY etc/supervisord.apache/ /etc/supervisord/
COPY src/ /var/www/html/

RUN apk add --update --no-cache --virtual .php-apache-rundeps apache2 apache2-utils apache2-proxy apache2-ssl supervisor \
    && touch /var/log/supervisord.log \
    && touch /var/run/supervisord.pid \
    && mkdir -p /run/apache2 /var/run/apache2 /var/log/apache2 /etc/supervisord \
    && rm -rf /var/cache/apk/* \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && chown -Rf 1001:0 /etc/apache2 /run/apache2 /var/run/apache2 /var/log/apache2 /var/www/html \
                        /var/log/supervisord.log /etc/supervisord /var/run/supervisord.pid \
    && chmod -R ug+rw /etc/apache2 /run/apache2 /var/run/apache2 /var/log/apache2 /var/lock /var/www/html \
                      /var/log/supervisord.log /etc/supervisord /var/run/supervisord.pid \
    && find /run/apache2 -type d -exec chmod ug+x {} \; \
    && find /etc/apache2 -type d -exec chmod ug+x {} \; \
    && find /run/apache2 -type d -exec chmod ug+x {} \; \
    && find /var/run/apache2 -type d -exec chmod ug+x {} \; \
    && find /var/log/apache2 -type d -exec chmod ug+x {} \; 

USER 1001

ENTRYPOINT ["container-entrypoint"]

HEALTHCHECK --start-period=10s --interval=1m --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord/supervisord.conf"]

FROM php-fpm-dev AS apache-dev

USER root

COPY etc/apache2/ /etc/apache2/
COPY etc/supervisord.apache/ /etc/supervisord/
COPY src/ /var/www/html/

RUN apk add --update --no-cache --virtual .php-apache-rundeps apache2 apache2-utils apache2-proxy apache2-ssl supervisor \
    && touch /var/log/supervisord.log \
    && touch /var/run/supervisord.pid \
    && mkdir -p /run/apache2 /var/run/apache2 /var/log/apache2 /etc/supervisord \
    && rm -rf /var/cache/apk/* \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && chown -Rf 1001:0 /etc/apache2 /run/apache2 /var/run/apache2 /var/log/apache2 /var/www/html \
                        /var/log/supervisord.log /etc/supervisord /var/run/supervisord.pid \
    && chmod -R ug+rw /etc/apache2 /run/apache2 /var/run/apache2 /var/log/apache2 /var/lock /var/www/html \
                      /var/log/supervisord.log /etc/supervisord /var/run/supervisord.pid \
    && find /run/apache2 -type d -exec chmod ug+x {} \; \
    && find /etc/apache2 -type d -exec chmod ug+x {} \; \
    && find /run/apache2 -type d -exec chmod ug+x {} \; \
    && find /var/run/apache2 -type d -exec chmod ug+x {} \; \
    && find /var/log/apache2 -type d -exec chmod ug+x {} \; 

USER 1001

ENTRYPOINT ["container-entrypoint"]

HEALTHCHECK --start-period=10s --interval=1m --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord/supervisord.conf"]

FROM php-fpm-prod AS nginx-prod

USER root

COPY etc/nginx/ /etc/nginx/
COPY etc/supervisord.nginx/ /etc/supervisord/
COPY src/ /usr/share/nginx/html/

RUN apk add --update --no-cache --virtual .php-nginx-rundeps nginx supervisor \
    && touch /var/log/supervisord.log \
    && touch /var/run/supervisord.pid \
    && mkdir -p /etc/nginx/sites-enabled /var/log/nginx /var/cache/nginx \
                /var/run/nginx /var/lib/nginx /usr/share/nginx/cache/fcgi /var/tmp/nginx \
                /etc/supervisord \
    && rm -rf /etc/nginx/conf.d/default.conf /var/cache/apk/* \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && chown -Rf 1001:0 /etc/nginx /var/log/nginx /var/run/nginx /var/cache/nginx \
                        /var/lib/nginx /usr/share/nginx /var/tmp/nginx \
                        /var/log/supervisord.log /etc/supervisord /var/run/supervisord.pid \
    && chmod -R ug+rw /etc/nginx /var/log/nginx /var/run/nginx /var/cache/nginx \
                      /var/lib/nginx /usr/share/nginx /var/tmp/nginx \
                      /var/log/supervisord.log /etc/supervisord /var/run/supervisord.pid \
    && find /etc/nginx -type d -exec chmod ug+x {} \; \
    && find /var/log/nginx -type d -exec chmod ug+x {} \; \
    && find /var/run/nginx -type d -exec chmod ug+x {} \; \
    && find /var/lib/nginx -type d -exec chmod ug+x {} \; \
    && find /var/tmp/nginx -type d -exec chmod ug+x {} \; \
    && find /usr/share/nginx -type d -exec chmod ug+x {} \; 

USER 1001

ENTRYPOINT ["container-entrypoint"]

HEALTHCHECK --start-period=10s --interval=1m --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord/supervisord.conf"]

FROM php-fpm-dev AS nginx-dev

USER root

COPY etc/nginx/ /etc/nginx/
COPY etc/supervisord.nginx/ /etc/supervisord/
COPY src/ /usr/share/nginx/html/

RUN apk add --update --no-cache --virtual .php-nginx-rundeps nginx supervisor \
    && touch /var/log/supervisord.log \
    && touch /var/run/supervisord.pid \
    && mkdir -p /etc/nginx/sites-enabled /var/log/nginx /var/cache/nginx \
                /var/run/nginx /var/lib/nginx /usr/share/nginx/cache/fcgi /var/tmp/nginx \
                /etc/supervisord \
    && rm -rf /etc/nginx/conf.d/default.conf /var/cache/apk/* \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && chown -Rf 1001:0 /etc/nginx /var/log/nginx /var/run/nginx /var/cache/nginx \
                        /var/lib/nginx /usr/share/nginx /var/tmp/nginx \
                        /var/log/supervisord.log /etc/supervisord /var/run/supervisord.pid \
    && chmod -R ug+rw /etc/nginx /var/log/nginx /var/run/nginx /var/cache/nginx \
                      /var/lib/nginx /usr/share/nginx /var/tmp/nginx \
                      /var/log/supervisord.log /etc/supervisord /var/run/supervisord.pid \
    && find /etc/nginx -type d -exec chmod ug+x {} \; \
    && find /var/log/nginx -type d -exec chmod ug+x {} \; \
    && find /var/run/nginx -type d -exec chmod ug+x {} \; \
    && find /var/lib/nginx -type d -exec chmod ug+x {} \; \
    && find /var/tmp/nginx -type d -exec chmod ug+x {} \; \
    && find /usr/share/nginx -type d -exec chmod ug+x {} \; 

USER 1001

ENTRYPOINT ["container-entrypoint"]

HEALTHCHECK --start-period=10s --interval=1m --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord/supervisord.conf"]
