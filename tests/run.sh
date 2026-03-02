#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

cid="$(docker run -d -e DEBUG -e OPENCLAW_GATEWAY_TOKEN=bad-token --name "${NAME}" "${IMAGE}")"
trap "docker rm -vf $cid > /dev/null" EXIT

exec() {
	docker exec ${cid} "${@}"
}

exec make check-ready -f /usr/local/bin/actions.mk max_try=10 host="${NAME}"

echo -n "Checking Openclaw version... "
exec openclaw --version | grep -q "${OPENCLAW_VER}"
echo "OK"

echo -n "Checking Openclaw status... "
exec openclaw status --json | grep -q "heartbeat"
echo "OK"
