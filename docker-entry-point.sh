#!/bin/sh
set -e

if [ "$1" == 'redis-server' ]; then
	exec gosu redis "$@"
fi

exec "$@"
