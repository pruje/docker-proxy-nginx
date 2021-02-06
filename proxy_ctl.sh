#!/bin/bash
#
#  Proxy controller
#

#
#  Functions
#

print_help() {
	echo "Usage: proxy_ctl COMMAND"
	echo "Commands:"
	echo "   up [COMPOSE_OPTIONS]          Run proxy container (in detached mode)"
	echo "   start                         Start proxy container"
	echo "   test                          Test your nginx config"
	echo "   reload [-f|--force]           Reload config (force option to disable configs with issues)"
	echo "   maintenance on|off [FILE...]  Put a nginx config file in/out maintenance mode (--yes to not confirm)"
	echo "   certbot [ARGS]                Run certbot command"
	echo "   stop [COMPOSE_OPTIONS]        Stop proxy container"
	echo "   restart [COMPOSE_OPTIONS]     Restart proxy container"
	echo "   down [COMPOSE_OPTIONS]        Stop & delete proxy container"
	echo "   status                        Get status of the proxy container"
	echo "   connect                       Connect to the proxy container (opens a bash session)"
	echo "   upgrade                       Upgrade proxy from git"
	echo "   build [COMPOSE_OPTIONS]       Build proxy image"
	echo "   help                          Print this help"
}

# Check if an array contains a value
# Usage: lb_in_array VALUE "${ARRAY[@]}"
lb_in_array() {
	[ -z "$1" ] && return 1

	# get search value
	local value search=$1
	shift

	# if array is empty, return not found
	[ $# = 0 ] && return 2

	# parse array to find value
	for value in "$@" ; do
		[ "$value" = "$search" ] && return 0
	done

	# not found
	return 2
}

# Pull nginx image
_pull_image() {
	docker pull "$(grep '^FROM ' Dockerfile | awk '{print $2}')"
}

# Build proxy image
_build() {
	# force repull nginx image
	if lb_in_array --no-cache "$@" ; then
		_pull_image || return
	fi
	docker-compose build "$@"
}


#
#  Main program
#

# get real path of the script
if [ "$(uname)" = Darwin ] ; then
	# macOS which does not support readlink -f option
	script_path=$(perl -e 'use Cwd "abs_path";print abs_path(shift)' "$0")
else
	script_path=$(readlink -f "$0")
fi

cd "$(dirname "$script_path")" || exit 1

case $1 in
	up)
		# ignore "up" argument
		shift

		# add --detach option if not specified (but avoid duplicate option)
		if lb_in_array -d "$@" || lb_in_array --detach "$@" ; then
			opts=""
		else
			opts="-d"
		fi

		# force detatch option
		docker-compose up $opts "$@"
		;;
	build)
		shift
		_build "$@"
		;;
	start|stop|restart|down|logs)
		docker-compose "$@"
		;;
	status)
		docker-compose ps -a
		;;
	certbot)
		docker-compose exec nginx "$@"
		;;
	connect)
		docker-compose exec nginx bash
		;;
	upgrade)
		echo "Upgrade proxy..."
		git pull && _pull_image && _build
		res=$?
		if [ $res = 0 ] ; then
			echo "Run 'proxy_ctl up' to restart the upgraded proxy."
		else
			exit $res
		fi
		;;
	help)
		print_help
		;;
	'')
		print_help
		exit 1
		;;
	*)
		# other: redirect to proxy script inside container
		docker-compose exec nginx proxy_ctl "$@"
		;;
esac
