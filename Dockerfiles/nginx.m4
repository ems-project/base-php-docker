LABEL be.fgov.elasticms.base.variant="nginx"

USER root

ENV NGINX_ENABLED=true

COPY --chmod=775 --chown=root:root etc/nginx/ /etc/nginx/
COPY --chmod=775 --chown=root:root etc/supervisord.nginx/supervisord.conf /etc/supervisord.conf
COPY --chmod=664 --chown=1001:0 src/ /usr/share/nginx/html/
COPY --chmod=775 --chown=1001:0 config/nginx/ /app/config/nginx/

RUN mkdir -p /app/etc/nginx/sites-enabled \
             /app/var/run/nginx \
             /app/var/cache/nginx/fcgi \
             /app/var/tmp/client \
             /app/var/tmp/scgi \
             /app/var/tmp/fastcgi \
             /app/var/tmp/uwsgi \
             /app/var/tmp/scgi  \
    && apk add --update --no-cache --virtual .php-nginx-rundeps nginx \
                                                                nginx-mod-http-headers-more \
                                                                nginx-mod-http-vts \
    && rm -rf /etc/nginx/conf.d/default.conf /var/cache/apk/* \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && find /var/lib/nginx -type d -exec chmod ugo+rx {} \; \
    && chown -Rf 1001:0 /app/etc/nginx \
                        /app/var/run/nginx \
                        /app/var/cache/nginx \
                        /app/var/tmp \
    && chmod -R ugo+rw /app/etc/nginx \
                       /app/var/run/nginx \
                       /app/var/cache/nginx \
                       /app/var/tmp

USER 1001

EXPOSE 9090/tcp

ENTRYPOINT ["container-entrypoint"]

HEALTHCHECK --start-period=2s --interval=10s --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
