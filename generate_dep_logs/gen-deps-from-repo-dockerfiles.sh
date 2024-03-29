#!/bin/bash
set -x  # turn on debugging
set -e

########################################################################
#
# Generate dependencies-*.log for each Dockerfile*
#
########################################################################


# install podman if needed... (grep -o -> 1 if found)
if [[ $(grep -o "USER" ./Dockerfile) ]]; then
    podman --version
    # 'uid' & 'gid' were added in https://github.com/containers/podman/releases/tag/v4.3.0
    $GITHUB_ACTION_PATH/utils/install-podman.sh
    podman --version
    USE_PODMAN='--podman'
fi


# 1st - the dockerfiles in $DOCKERFILE_NAMETAGS
for fname_nametag in $DOCKERFILE_NAMETAGS; do
    echo $fname_nametag
    docker images
    fname=$(echo $fname_nametag | cut -d ':' -f1)
    nametag=$(echo $fname_nametag | cut -d ':' -f2-)
    $GITHUB_ACTION_PATH/generate_dep_logs/gen-deps.sh \
        $fname \
        "dependencies-from-$(basename $fname).log" \
        "within the container built from '$fname'" \
        $nametag \
        $USE_PODMAN
done
# 2nd - the rest of the dockerfiles
for fname in ./Dockerfile*; do
    if [[ $DOCKERFILE_NAMETAGS == *$(basename $fname):* ]]; then
        continue
    fi
    echo $fname
    docker images
    $GITHUB_ACTION_PATH/generate_dep_logs/gen-deps.sh \
        $fname \
        "dependencies-from-$(basename $fname).log" \
        "within the container built from '$fname'" \
        $USE_PODMAN
done