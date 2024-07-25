#!/bin/bash
echo && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "$( basename "$0" )..." && echo
set -ex

########################################################################
#
# Generate dependencies-log file for the given docker image
#
########################################################################

cd $REPO_PATH
ls

########################################################################

# GET ARGS
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: gen-deps-within-container.sh DOCKER_IMAGE DEPS_LOG_FILE SUBTITLE [--podman]"
    exit 1
else
    DOCKER_IMAGE="$1"
    DEPS_LOG_FILE="$2"
    SUBTITLE="$3"
fi

# VALIDATE ARGS
if [ -z "$(docker images -q $DOCKER_IMAGE 2> /dev/null)" ]; then
    echo "ERROR: image not found: $DOCKER_IMAGE"
    exit 2
fi

########################################################################

# move script
TEMPDIR=$(mktemp -d) && trap 'rm -rf "$TEMPDIR"' EXIT
cp $GITHUB_ACTION_PATH/generate_dep_logs/pip-freeze-tree.sh $TEMPDIR
chmod +x $TEMPDIR/pip-freeze-tree.sh


# build & generate
if [[ $* == *--podman* ]]; then  # look for flag anywhere in args
    # 'uid' & 'gid' were added in https://github.com/containers/podman/releases/tag/v4.3.0
    podman run --rm -i \
        --env PACKAGE_NAME=$PACKAGE_NAME \
        --env ACTION_REPOSITORY=$ACTION_REPOSITORY \
        --env SUBTITLE="$SUBTITLE" \
        --mount type=bind,source=$(realpath $TEMPDIR/),target=/local/$TEMPDIR \
        --userns=keep-id:uid=1000,gid=1000 \
        $DOCKER_IMAGE \
        /local/$TEMPDIR/pip-freeze-tree.sh /local/$TEMPDIR/$DEPS_LOG_FILE
else
    docker run --rm -i \
        --env PACKAGE_NAME \
        --env ACTION_REPOSITORY \
        --env SUBTITLE \
        --mount type=bind,source=$(realpath $TEMPDIR/),target=/local/$TEMPDIR \
        $DOCKER_IMAGE \
        /local/$TEMPDIR/pip-freeze-tree.sh /local/$TEMPDIR/$DEPS_LOG_FILE
fi

ls $TEMPDIR
mv $TEMPDIR/$DEPS_LOG_FILE $DEPS_LOG_FILE
