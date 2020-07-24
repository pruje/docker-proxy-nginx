#!/bin/bash
#
#  Proxy controller
#

print_help() {
	echo "Usage: proxy_ctl COMMAND"
	echo "Commands:"
	echo "  up           Run proxy container"
	echo "  start        Start proxy container"
	echo "  test         Test config"
	echo "  reload       Reload config"
	echo "  maintenance  Put a file in maintenance mode (use it a with file path)"
	echo "  online       Get a file out of maintenance mode (use it with file path)"
	echo "  certbot      Run certbot command (use it with arguments)"
	echo "  stop         Stop proxy container"
	echo "  restart      Restart proxy container"
	echo "  down         Stop & delete proxy container"
	echo "  status       Get status of the proxy container"
	echo "  connect      Connect to the proxy container (open a bash session)"
	echo "  build        Build proxy image"
	echo "  help         Print this help"
}

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

		# avoid double -d option
		[ "$1" = "-d" ] && shift

		# force detatch option
		docker-compose up -d "$@"
		;;
	build|start|stop|restart|down)
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
