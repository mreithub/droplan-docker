#!/bin/sh

set -ex

if [ -z "$DO_INTERVAL" ]; then
	# specifies the default launch interval
	DO_INTERVAL=300
fi

SUCCESSFUL=
while true; do
	rc=0
	./droplan "$@" || rc="$?"
	if [ "$rc" -ne 0 ]; then
		# droplan failed. See if that happened before
		if [ -z "$SUCCESSFUL" ]; then
			echo "ERROR: droplan exited with code $rc" >&2
			exit "$rc"
		else
			echo "ERROR: droplan exited with code $rc, restarting in ${DO_INTERVAL}s" >&2
		fi
	fi

	SUCCESSFUL='yes'
	sleep "$DO_INTERVAL"
done
