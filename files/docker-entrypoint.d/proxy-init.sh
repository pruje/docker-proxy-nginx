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
		exit 1
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

	if ! [ -f /etc/letsencrypt/cli.ini ] ; then
		echo "Initialization of letsencrypt config..."
		echo "max-log-backups = 0" > /etc/letsencrypt/cli.ini
		result || exit 1
	fi

	if ! [ -d /etc/letsencrypt/accounts ] ; then
		echo "Register certbot..."
		if [ -n "$LETSENCRYPT_EMAIL" ] ; then
			register_opts=(-m $LETSENCRYPT_EMAIL)
		else
			register_opts=(--register-unsafely-without-email)
		fi
		certbot register --agree-tos --no-eff-email "${register_opts[@]}"
		result || exit 1
	fi

	# first run of certbot only to create config files; do not care of errors
	if ! [ -f /etc/letsencrypt/options-ssl-nginx.conf ] ; then
		echo "Initialize certbot..."
		echo c | certbot &> /dev/null
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
result
