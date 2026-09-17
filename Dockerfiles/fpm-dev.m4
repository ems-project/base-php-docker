ARG COMPOSER_VERSION_ARG
ARG NODE_VERSION_ARG
ARG PHP_EXT_XDEBUG_VERSION_ARG

ENV PHP_EXT_XDEBUG_VERSION=${PHP_EXT_XDEBUG_VERSION_ARG:-3.5.3}

LABEL be.fgov.elasticms.base.environment="dev" \
      be.fgov.elasticms.base.node-version="${NODE_VERSION_ARG:-20}" \
      be.fgov.elasticms.base.composer-version="${COMPOSER_VERSION_ARG:-2.10.3}"

USER root

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/include/node /usr/local/include/node
COPY --from=node /opt/ /opt/

RUN echo "Install and Configure Node ..." \
    && apk add --no-cache --virtual .php-dev-rundeps git patch libstdc++ libgcc \
    && ln -sf ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && ln -sf ../lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack \
    && ln -sf /opt/yarn-v*/bin/yarn /usr/local/bin/yarn \
    && ln -sf /opt/yarn-v*/bin/yarnpkg /usr/local/bin/yarnpkg \
    && node --version && npm --version && yarn --version \
    && echo "Install and Configure required extra PHP packages ..." \
    && apk add --update --no-cache --virtual .build-deps $PHPIZE_DEPS autoconf coreutils linux-headers \
    && pecl install xdebug-${PHP_EXT_XDEBUG_VERSION} \
    && docker-php-ext-enable xdebug \
    && runDeps="$( \
       scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
       | tr ',' '\n' \
       | sort -u \
       | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
       )" \
    && apk add --no-cache --virtual .php-dev-phpext-rundeps $runDeps \
    && apk add --no-cache --virtual .php-dev-rundeps git patch \
    && echo "Configure Xdebug ..." \
    && echo '[xdebug]' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && echo 'xdebug.mode=debug' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && echo 'xdebug.start_with_request=yes' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && echo 'xdebug.client_port=9003' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && echo 'xdebug.client_host=host.docker.internal' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" \
    && rm -rf /var/cache/apk/* \
    && echo "Configure Composer ..." \
    && mkdir /home/default/.composer \
    && chown 1001:0 /home/default/.composer \
    && chmod -R ugo+rw /home/default/.composer \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/*

EXPOSE 9003

USER 1001
