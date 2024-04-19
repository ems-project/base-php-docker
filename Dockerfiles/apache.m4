LABEL be.fgov.elasticms.base.variant="apache"

USER root

COPY --chmod=775 --chown=1001:0 etc/apache2/ /etc/apache2/
COPY --chmod=775 --chown=1001:0 etc/supervisord.apache/ /etc/supervisord/
COPY --chmod=775 --chown=1001:0 src/ /var/www/html/

RUN apk add --update --no-cache --virtual .php-apache-rundeps apache2 apache2-utils apache2-proxy apache2-ssl \
    && mkdir -p /run/apache2 /var/run/apache2 /var/log/apache2 \
    && rm -rf /var/cache/apk/* \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && chown -Rf 1001:0 /etc/apache2 /run/apache2 /var/run/apache2 /var/log/apache2 /var/www/html \
    && chmod -R ugo+rw /etc/apache2 /run/apache2 /var/run/apache2 /var/log/apache2 /var/www/html \
    && find /run/apache2 -type d -exec chmod ugo+x {} \; \
    && find /etc/apache2 -type d -exec chmod ugo+x {} \; \
    && find /run/apache2 -type d -exec chmod ugo+x {} \; \
    && find /var/run/apache2 -type d -exec chmod ugo+x {} \; \
    && find /var/log/apache2 -type d -exec chmod ugo+x {} \;

USER 1001

ENTRYPOINT ["container-entrypoint"]

HEALTHCHECK --start-period=10s --interval=1m --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord/supervisord.conf"]