#!/bin/bash

echo "entrypoint: activating docker daemon..."
dockerd > /var/log/dockerd.log 2>&1 &
sleep 10

echo "entrypoint: executing command: $@"
exec "$@"
