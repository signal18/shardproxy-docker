#!/bin/bash
set -eo pipefail
shopt -s nullglob

SHARDPROXY_ROOT_HOST="%"

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
	set -- mysqld "$@"
fi

# skip setup if they want an option that stops mysqld
wantHelp=
for arg; do
	case "$arg" in
		-'?'|--help|--print-defaults|-V|--version)
			wantHelp=1
			break
			;;
	esac
done

if [ ! -z "$SHARDPROXY_ROOT_PASSWORD" ]; then

	mysql=( mysql --protocol=socket -uroot -hlocalhost --socket=/var/lib/shardproxy/mysql.sock )

	"$@" --skip-networking --socket=/var/lib/shardproxy/mysql.sock &
	pid="$!"

	for i in {30..0}; do
		if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
			break
		fi
		echo 'Init process in progress...'
		sleep 1
	done
	if [ "$i" = 0 ]; then
		echo >&2 'Init process failed.'
		exit 1
	fi

	if [ ! -z "$SHARDPROXY_ROOT_PASSWORD" ]; then
		echo "Setting up root password..."
		"${mysql[@]}" -e "CREATE USER 'root'@'${SHARDPROXY_ROOT_HOST}' IDENTIFIED BY '${SHARDPROXY_ROOT_PASSWORD}'"
		"${mysql[@]}" -e "GRANT ALL ON *.* TO 'root'@'${SHARDPROXY_ROOT_HOST}' WITH GRANT OPTION"
	fi

	if ! kill -s TERM "$pid" || ! wait "$pid"; then
		echo >&2 'MySQL init process failed.'
		exit 1
	fi

	echo
	echo 'Init process done. Ready for start up.'
	echo
fi

exec "$@"

