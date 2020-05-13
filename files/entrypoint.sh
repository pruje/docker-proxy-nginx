#!/bin/bash

#
#  Functions
#

task() {
	echo -n "$*..."
}

result() {
	local result=$?
	if [ $result = 0 ] ; then
		echo "	[ OK ]"
	else
		echo "	[ FAILED ]"
	fi

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
	task "Generate self-signed certificate"
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
if [ "$LETSENCRYPT_ENABLE" = true ] && ! [ -f /etc/letsencrypt/cli.ini ] ; then

	if [ -z "$LETSENCRYPT_EMAIL" ] ; then
		error "Email for letsencrypt must be set!"
		exit 1
	fi

	# create default config for letsencrypt
	task "Initialization of letsencrypt config"
	echo "max-log-backups = 0" > /etc/letsencrypt/cli.ini
	result || exit 1

	# first run of certbot
	task "First run of certbot"
	certbot register -m $LETSENCRYPT_EMAIL --agree-tos --no-eff-email > /dev/null
	result || exit 1

	# create cron task to autorenew certificates
	task "Create certbot cron task"
	mkdir -p /etc/cron.d && \
	echo "0 0,12 * * *    root    python3 -c 'import random; import time; time.sleep(random.random() * 3600)' && /usr/local/bin/certbot renew -q" > /etc/cron.d/certbot
	result || warn "You must renew certificates manually"
fi


#
#  Starting services
#

task "Start cron"
cron
result

# prepare to start
proxy_ctl init

task "Start nginx..."

# run command
"$@"
exit $?
