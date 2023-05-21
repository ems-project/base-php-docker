LABEL be.fgov.elasticms.base.variant="nginx"

USER root

COPY --chmod=775 --chown=1001:0 etc/nginx/ /etc/nginx/
COPY --chmod=775 --chown=1001:0 etc/supervisord.nginx/ /etc/supervisord/
COPY --chmod=775 --chown=1001:0 src/ /usr/share/nginx/html/

RUN apk add --update --no-cache --virtual .php-nginx-rundeps nginx \
    && mkdir -p /var/log/nginx /var/cache/nginx /var/tmp/nginx \
                /var/run/nginx /var/lib/nginx /usr/share/nginx/cache/fcgi \
    && rm -rf /etc/nginx/conf.d/default.conf /var/cache/apk/* \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && chown -Rf 1001:0 /etc/nginx /var/log/nginx /var/run/nginx /var/cache/nginx \
                        /var/lib/nginx /usr/share/nginx /var/tmp/nginx \
    && chmod -R ug+rw /etc/nginx /var/log/nginx /var/run/nginx /var/cache/nginx \
                      /var/lib/nginx /usr/share/nginx /var/tmp/nginx \
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