LABEL be.fgov.elasticms.base.variant="apache"

USER root

ENV APACHE_ENABLED=true

COPY --chmod=775 --chown=root:root etc/apache2/ /etc/apache2/
COPY --chmod=664 --chown=root:root etc/supervisord.apache/supervisord.conf /etc/supervisord.conf
COPY --chmod=664 --chown=1001:0 src/ /var/www/localhost/htdocs/
COPY --chmod=775 --chown=1001:0 config/apache2/ /app/config/apache2/

RUN mkdir -p /app/var/cache/apache2/mod_ssl \
             /app/etc/apache2/conf.d \
             /app/var/run/apache2 \
    && apk add --update --no-cache --virtual .php-apache-rundeps apache2 apache2-utils apache2-proxy apache2-ssl \
    && sed -i 's/^\([[:space:]]*\)Listen /\1#Listen /' /etc/apache2/httpd.conf \
    && sed -i 's/^\([[:space:]]*\)LoadModule mpm_prefork_module /\1#LoadModule mpm_prefork_module /' /etc/apache2/httpd.conf \
    && sed -i 's/^\([[:space:]]*\)LogLevel /\1#LogLevel /' /etc/apache2/httpd.conf \
    && sed -i 's/^\([[:space:]]*\)ErrorLog /\1#ErrorLog /' /etc/apache2/httpd.conf \
    && sed -i 's/^\([[:space:]]*\)CustomLog /\1#CustomLog /' /etc/apache2/httpd.conf \
    && rm -rf /var/cache/apk/* \
    && chown -Rf 1001:0 /app/var/cache/apache2 \
                        /app/etc/apache2 \
                        /app/var/run/apache2 \
    && chmod -R ugo+rw /app/var/cache/apache2 \
                       /app/etc/apache2 \
                       /app/var/run/apache2

USER 1001

ENTRYPOINT ["container-entrypoint"]

HEALTHCHECK --start-period=2s --interval=1m --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
