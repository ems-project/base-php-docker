ARG VERSION_ARG
ARG RELEASE_ARG
ARG BUILD_DATE_ARG
ARG VCS_REF_ARG
ARG AWS_CLI_VERSION_ARG
ARG PHP_EXT_REDIS_VERSION_ARG
ARG PHP_EXT_APCU_VERSION_ARG

LABEL be.fgov.elasticms.base.build-date=$BUILD_DATE_ARG \
      be.fgov.elasticms.base.name="Base PHP 8.3.x Docker Image" \
      be.fgov.elasticms.base.description="Docker base image is the basic image on which you add layers (which are basically filesystem changes) and create a final image containing your App." \
      be.fgov.elasticms.base.url="https://hub.docker.com/repository/docker/elasticms/base-php" \
      be.fgov.elasticms.base.vcs-ref=$VCS_REF_ARG \
      be.fgov.elasticms.base.vcs-url="https://github.com/ems-project/base-php-docker" \
      be.fgov.elasticms.base.vendor="sebastian.molle@gmail.com" \
      be.fgov.elasticms.base.version="$VERSION_ARG" \
      be.fgov.elasticms.base.release="$RELEASE_ARG" \
      be.fgov.elasticms.base.environment="prd" \
      be.fgov.elasticms.base.variant="fpm" \
      be.fgov.elasticms.base.schema-version="1.0"

USER root

ENV AWS_CLI_VERSION=${AWS_CLI_VERSION_ARG:-2.13.5} \
    PHP_EXT_REDIS_VERSION=${PHP_EXT_REDIS_VERSION_ARG:-6.0.2} \
    PHP_EXT_APCU_VERSION=${PHP_EXT_APCU_VERSION_ARG:-5.1.23} \
    PHP_FPM_MAX_CHILDREN=${PHP_FPM_MAX_CHILDREN:-5} \
    PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES=${PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES:-128} \
    CONTAINER_HEAP_PERCENT=${CONTAINER_HEAP_PERCENT:-0.80} \
    HOME=/home/default \
    TMPDIR=/app/tmp \
    PATH=/opt/bin:/usr/local/bin:/usr/bin:$PATH

COPY --from=hairyhenderson/gomplate:stable /gomplate /usr/bin/gomplate
COPY --chmod=664 --chown=1001:0 config/php/ /app/config/php/
COPY --chmod=664 --chown=1001:0 config/supervisor.d/ /app/config/supervisor.d/

COPY --chmod=775 --chown=root:root bin/ /usr/local/bin/

RUN mkdir -p /home/default \
             /app/var/lock \
             /app/var/log \
             /app/var/run/varnish \
             /app/var/run/php-fpm \
             /app/var/cache/varnish/varnishd \
             /app/etc/php/php-fpm.d \
             /app/etc/supervisor.d \
             /app/bin/container-entrypoint.d \
             /app/src \
             /app/tmp \
    && echo "include=/app/etc/php/php-fpm.d/*.conf" >> /usr/local/etc/php-fpm.conf \
    && chmod +x /usr/local/bin/apk-list \
                /usr/local/bin/container-entrypoint \
                /usr/local/bin/wait-for-it \
    && echo "Upgrade all already installed packages ..." \
    && apk upgrade --available \
    && echo "Install and Configure required extra PHP packages ..." \
    && apk add --update --no-cache --virtual .build-deps $PHPIZE_DEPS autoconf freetype-dev icu-dev \
                                                libjpeg-turbo-dev libpng-dev libwebp-dev libxpm-dev \
                                                libzip-dev openldap-dev pcre-dev gnupg git bzip2-dev \
                                                musl-libintl postgresql-dev libxml2-dev tidyhtml-dev \
                                                libxslt-dev \
    && docker-php-ext-configure gd --with-freetype --with-webp --with-jpeg \
    && docker-php-ext-configure tidy --with-tidy \
    && docker-php-ext-install -j "$(nproc)" soap bz2 fileinfo gettext intl pcntl pgsql \
                                            pdo_pgsql ldap gd ldap mysqli pdo_mysql \
                                            zip bcmath exif tidy xsl \
    && pecl install APCu-${PHP_EXT_APCU_VERSION} \
    && pecl install redis-${PHP_EXT_REDIS_VERSION} \
    && docker-php-ext-enable apcu redis opcache \
    && runDeps="$( \
       scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
       | tr ',' '\n' \
       | sort -u \
       | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
       )" \
    && apk add --update --no-cache --virtual .ems-phpext-rundeps $runDeps \
    && apk add --update --upgrade --no-cache --virtual .ems-rundeps tzdata \
                                      bash gettext ssmtp postgresql-client postgresql-libs \
                                      libjpeg-turbo freetype libpng libwebp libxpm mailx libxslt coreutils \
                                      mysql-client jq icu-libs libxml2 python3 py3-pip groff supervisor \
                                      varnish tidyhtml \
                                      aws-cli=~${AWS_CLI_VERSION} \
    && mv /etc/supervisord.conf /etc/supervisord.conf.orig \
    && touch /app/var/log/supervisord.log \
             /app/var/run/supervisord.pid \
             /app/var/cache/varnish/secret \
    && cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && echo "Setup timezone ..." \
    && cp /usr/share/zoneinfo/Europe/Brussels /etc/localtime \
    && echo "Europe/Brussels" > /etc/timezone \
    && echo "Add non-privileged user ..." \
    && adduser -D -u 1001 -g default -G root -s /sbin/nologin default \
    && echo "Configure OpCache ..." \
    && echo 'opcache.memory_consumption=128' > /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo 'opcache.interned_strings_buffer=8' >> /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo 'opcache.max_accelerated_files=4000' >> /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo 'opcache.revalidate_freq=2' >> /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo 'opcache.fast_shutdown=1' >> /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && cd /opt \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && chown -Rf 1001:0 /home/default /app \
    && chmod -R ugo+rw /home/default /app \
    && find /app -type d -exec chmod ugo+x {} \;

USER 1001

ENTRYPOINT ["container-entrypoint"]

EXPOSE 6081/tcp 6082/tcp

HEALTHCHECK --start-period=2s --interval=10s --timeout=5s --retries=5 \
        CMD bash -c '[ -S /var/run/php-fpm/php-fpm.sock ]'

CMD ["php-fpm", "-F", "-R"]
