#!/bin/bash
sleep 0.1 && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "$( basename "$0" )..." && echo
set -ex

########################################################################
#
# Generate dependencies-*.log for each user-supplied image
#
########################################################################

ls $REPO_PATH

# install podman if needed... (grep -o -> 1 if found)
if [[ $(grep -o "USER" $REPO_PATH/Dockerfile) ]]; then
    podman --version
    # 'uid' & 'gid' were added in https://github.com/containers/podman/releases/tag/v4.3.0
    $GITHUB_ACTION_PATH/utils/install-podman.sh
    podman --version
    USE_PODMAN='--podman'
fi

# get images to dep
images_to_dep=$(docker images | awk -v pat="$DOCKER_TAG_TO_DEP" '$2==pat' | awk -F ' ' '{print $1":"$2}')

# compare counts of dockerfiles vs images, yes not perfect (considering build args) but moderately effective
n_images=$( echo "$images_to_dep" | wc -l )
n_dockerfiles=$( find $REPO_PATH -name "Dockerfile*" -printf '.' | wc -m )
if (( n_dockerfiles > n_images )); then
    echo "ERROR: $n_dockerfiles 'Dockerfile*' files found but $n_images pre-built Docker images (with tag='$DOCKER_TAG_TO_DEP') were provided"
    exit 1
fi

# dep each image
for image in $images_to_dep; do
    echo $image
    $GITHUB_ACTION_PATH/generate_dep_logs/gen-deps-within-container.sh \
        $image \
        "$REPO_PATH/dependencies-docker-$( echo $image | cut -d ":" -f 1 | tr '/' '-' ).log" \
        "within a container built from the user-supplied image '$( echo $image | cut -d ":" -f 1 )'" \
        $USE_PODMAN
done

sleep 0.1 && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
