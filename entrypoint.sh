#!/bin/bash

echo "entrypoint: activating docker daemon..."
dockerd > /var/log/dockerd.log 2>&1 &
sleep 1

echo "entrypoint: executing command: $@"
exec "$@"
