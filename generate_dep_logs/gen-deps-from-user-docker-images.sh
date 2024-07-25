#!/bin/bash
set -x  # turn on debugging
set -e

########################################################################
#
# Generate dependencies-*.log for each user-supplied image
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

# get images to dep
images_to_dep=$(sudo docker images | awk -v pat="$DOCKER_TAG_TO_DEP" '$2==pat' | awk -F ' ' '{print $1":"$2}')
if [ -f ./Dockerfile* ] && [ -z $images_to_dep ]; then
    echo "ERROR: './Dockerfile*' found but no pre-built Docker images (with tag='$DOCKER_TAG_TO_DEP') were provided"
    exit 1
fi

# dep each image
for image in $images_to_dep; do
    echo $image
    $GITHUB_ACTION_PATH/generate_dep_logs/gen-deps.sh \
        $image \
        "dependencies-from-$(basename $image).log" \
        "within the container built from the user-supplied image: $image" \
        $USE_PODMAN
     docker image rm $image && docker system prune --all --force  # save disk space
done
