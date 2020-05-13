#!/bin/bash

#
#  Functions
#

result() {
	local result=$?
	[ $result != 0 ] && echo "... FAILED"
	return $result
}

warn() {
	echo "[WARN]  $*"
}

error() {
	echo "[ERROR]  $*"
}


#
#  Init
#

# create self-signed certificate if not exists
if ! [ -f /etc/ssl/nginx/default.crt ] ; then
	echo "Generate self-signed certificate..."
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/nginx/default.key -out /etc/ssl/nginx/default.crt > /dev/null <<EOF
$SELFSSL_COUNTRY
$SELFSSL_STATE
$SELFSSL_LOCALITY
$SELFSSL_ORG
$SELFSSL_OUN
$SELFSSL_CN
$SELFSSL_EMAIL
EOF
	if ! result ; then
		error "cannot create self-signed certificate"
		return 1
	fi
fi

# disable logrotate
if [ "$LOGROTATE_ENABLE" = false ] ; then
	if [ -f /etc/cron.daily/logrotate ] ; then
		mv /etc/cron.daily/logrotate /etc/cron.daily/.logrotate || \
			warn "cannot disable logrotate"
	fi
else
	if [ -f /etc/cron.daily/.logrotate ] ; then
		mv /etc/cron.daily/.logrotate /etc/cron.daily/logrotate || \
			warn "cannot enable logrotate"
	fi
fi

# create nginx default page if not exists
if ! [ -f /etc/nginx/html/index.html ] ; then
	if ! cp /usr/share/nginx/html/50x.html /etc/nginx/html/index.html ; then
		error "cannot initialize default nginx page"
		exit 1
	fi
fi

# Initialization of letsencrypt (if used)
if [ "$LETSENCRYPT_ENABLE" = true ] ; then

	if [ -z "$LETSENCRYPT_EMAIL" ] ; then
		error "Email for letsencrypt must be set!"
		exit 1
	fi

	echo "Install certbot... (may take a long time)"
	certbot --install-only <<EOF
Y
EOF
	result || exit 1

	# create default config for letsencrypt
	if ! [ -f /etc/letsencrypt/cli.ini ] ; then
		echo "Initialization of letsencrypt config..."
		echo "max-log-backups = 0" > /etc/letsencrypt/cli.ini
		result || exit 1

		echo "Register certbot..."
		certbot register -m $LETSENCRYPT_EMAIL --agree-tos --no-eff-email
		result || exit 1
	fi

	# create cron task to autorenew certificates
	if ! [ -f /etc/cron.d/certbot ] ; then
		echo "Create certbot cron task..."
		mkdir -p /etc/cron.d && \
		echo "0 0,12 * * *    root    python3 -c 'import random; import time; time.sleep(random.random() * 3600)' && /usr/local/bin/certbot renew -q" > /etc/cron.d/certbot
		result || warn "You must renew certificates manually"
	fi
fi


#
#  Starting services
#

echo "Start cron..."
cron
result

echo "Initialize nginx config..."
proxy_ctl init
result || exit 1

echo "Start nginx..."

# run command
"$@"
exit $?
