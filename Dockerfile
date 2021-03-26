# Nginx reverse proxy

FROM nginx:mainline

LABEL maintainer="jean@prunneaux.com"

# - install utils
# - delete nginx logs redirection
# - cleanup
RUN apt-get update && apt-get install -y curl vim certbot python-certbot-nginx logrotate && \
    rm -f /var/log/nginx/* && \
    apt-get clean && apt-get autoremove && rm -rf /var/lib/apt/lists/*

# copy all files
COPY files/ /

# give good permissions to files
RUN chown root:root /docker-entrypoint.d/proxy-init.sh /usr/local/bin/proxy_ctl && \
    chmod 755 /docker-entrypoint.d/proxy-init.sh /usr/local/bin/proxy_ctl

ENV VERSION=1.2.4
