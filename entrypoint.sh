#!/bin/bash
set -ex

echo "entrypoint: activating docker daemon..."
dockerd > /var/log/dockerd.log 2>&1 &
sleep 1

docker images

# load transferred docker images -- this is the simplest way to transfer host's images
for file in /saved-images/*; do
    echo "entrypoint: loading transferred docker image from $file"
    docker load -i $file && rm $file & pidlist="$pidlist $!"
done

# wait for all them
for pid in $pidlist; do
    sleep .1  # little sleep to help logs
    echo "waiting for $pid..."
    if ! wait -n $pid; then
        kill $pidlist 2>/dev/null
        exit 1
    fi
done

docker images

echo "entrypoint: executing command: $@"
exec "$@"
