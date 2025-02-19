#!/bin/bash
set -euo pipefail
sleep 0.1 && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "$(basename "$0")..." && echo
set -ex

########################################################################
#
# Generate dependencies-*.log for each user-supplied image
#
########################################################################

ls $REPO_PATH

########################################################################

if [ -z "$IMAGES_TO_DEP" ]; then
    echo "::error:: 'IMAGES_TO_DEP' was not given or is empty ('$IMAGES_TO_DEP')"
    exit 2
fi

########################################################################

# install podman if needed... (grep -o -> 1 if found)
if [[ $(grep -o "USER" $REPO_PATH/Dockerfile) ]]; then
    podman --version
    # 'uid' & 'gid' were added in https://github.com/containers/podman/releases/tag/v4.3.0
    $GITHUB_ACTION_PATH/utils/install-podman.sh
    podman --version
    USE_PODMAN='--podman'
fi

# dep each image
for image in $IMAGES_TO_DEP; do
    echo $image
    $GITHUB_ACTION_PATH/generate_dep_logs/gen-deps-within-container.sh \
        $image \
        "$REPO_PATH/dependencies-docker-$(echo $image | cut -d ":" -f 1 | tr '/' '-').log" \
        "within a container using the user-supplied image '$(echo $image | cut -d ":" -f 1)'" \
        $USE_PODMAN
done

sleep 0.1 && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
