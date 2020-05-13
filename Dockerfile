# Nginx reverse proxy

FROM nginx:mainline

LABEL maintainer="jean@prunneaux.com"

# - install utils
# - install certbot & give permissions
# - delete nginx logs redirection
# - cleanup
RUN apt-get update && apt-get install -y wget vim logrotate && \
    wget -O /usr/local/bin/certbot https://dl.eff.org/certbot-auto && \
    chown root:root /usr/local/bin/certbot && chmod 755 /usr/local/bin/certbot && \
    rm -f /var/log/nginx/* && \
    apt-get clean && apt-get autoremove && rm -r /var/lib/apt/lists/*

# copy all files
COPY files/ /

# give permissions to files
RUN chown root:root /entrypoint.sh /usr/local/bin/proxy_ctl && \
    chmod 755 /entrypoint.sh /usr/local/bin/proxy_ctl

ENTRYPOINT ["/entrypoint.sh"]

HEALTHCHECK --interval=5s --timeout=3s CMD nginx -t

CMD ["nginx", "-g", "daemon off;"]
