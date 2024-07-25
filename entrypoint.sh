#!/bin/bash
set -ex

echo "entrypoint: activating docker daemon..."
dockerd > /var/log/dockerd.log 2>&1 &
sleep 1

# load transferred docker images -- this is the simplest way to transfer host's images
# TODO: parallelize (and think if docker container actually needed)
for file in /saved-images/*; do
    echo "entrypoint: loading transferred docker image from $file"
    docker load -i $file
    rm $file  # save disk space
    docker images
done

echo "entrypoint: executing command: $@"
exec "$@"
