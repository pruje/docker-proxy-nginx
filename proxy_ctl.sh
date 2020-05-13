#!/bin/bash

usage() {
	echo "Usage: proxy_ctl COMMAND [OPTIONS]"
	echo "Commands:"
	echo "  up       Run proxy container"
	echo "  start    Start proxy container"
	echo "  test     Test config"
	echo "  reload   Reload config"
	echo "  stop     Stop proxy container"
	echo "  restart  Restart proxy container"
	echo "  down     Stop & delete proxy container"
	echo "  status   Get status of the proxy container"
	echo "  connect  Connect to the proxy container (open a bash session)"
	echo "  build    Build proxy image"
	echo "  help     Print this help"
}

run_compose() {
	cd "$dir_path" || return 1
	docker-compose "$@"
}

# get real path of the script
if [ "$(uname)" = Darwin ] ; then
	# macOS which does not support readlink -f option
	script_path=$(perl -e 'use Cwd "abs_path";print abs_path(shift)' "$0")
else
	script_path=$(readlink -f "$0")
fi

dir_path=$(dirname "$script_path")

# load environment file
source "$dir_path"/.env &> /dev/null 
if [ $? != 0 ] ; then
	echo "ERROR: env file not found or error in it"
	exit 1
fi

# usage error
if [ -z "$1" ] ; then
	usage
	exit 1
fi

case $1 in
	up)
		run_compose up -d
		;;
	build|start|stop|restart|down)
		run_compose $1
		;;
	status)
		docker inspect --format '{{.State.Status}}' $PROXY_NAME
		;;
	connect)
		docker exec -ti $PROXY_NAME bash
		;;
	help)
		usage
		;;
	*)
		# other: redirect to proxy script inside container
		docker exec -ti $PROXY_NAME proxy_ctl "$@"
		;;
esac

exit $?
