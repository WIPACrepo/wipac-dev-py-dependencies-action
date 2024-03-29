#!/bin/bash
set -x  # turn on debugging
set -e

########################################################################
#
# Generate dependencies-dockerfile*.log for given Dockerfile
#
########################################################################

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: gen-deps.sh DOCKERFILE DEPS_LOG_FILE SUBTITLE [IMAGE_NAMETAG] [--podman]"
    exit 1
fi
if [ ! -f "$1" ]; then
    echo "File Not Found: $1"
    exit 2
fi
DEPS_LOG_FILE="$2"
SUBTITLE="$3"
if [ -z "$4" ] || [[ "$4" == --* ]]; then  # optional -> get default (& not a flag)
    # lower basename without extension
    image="for-deps-$(echo $(basename ${DEPS_LOG_FILE%.*}) | awk '{print tolower($0)}')"
else
    image="$4"
fi


# move script
TEMPDIR=$(mktemp -d)
trap 'rm -rf "$TEMPDIR"' EXIT
cp $GITHUB_ACTION_PATH/generate_dep_logs/pip-freeze-tree.sh $TEMPDIR
chmod +x $TEMPDIR/pip-freeze-tree.sh


# build & generate
if [[ $* == *--podman* ]]; then  # look for flag anywhere in args
    podman build -t $image --file $1 .
    # 'uid' & 'gid' were added in https://github.com/containers/podman/releases/tag/v4.3.0
    podman run --rm -i \
        --env PACKAGE_NAME=$PACKAGE_NAME \
        --env ACTION_REPOSITORY=$ACTION_REPOSITORY \
        --env SUBTITLE="$SUBTITLE" \
        --mount type=bind,source=$(realpath $TEMPDIR/),target=/local/$TEMPDIR \
        --userns=keep-id:uid=1000,gid=1000 \
        $image \
        /local/$TEMPDIR/pip-freeze-tree.sh /local/$TEMPDIR/$DEPS_LOG_FILE
else
    docker build -t $image --file $1 .
    docker run --rm -i \
        --env PACKAGE_NAME=$PACKAGE_NAME \
        --env ACTION_REPOSITORY=$ACTION_REPOSITORY \
        --env SUBTITLE="$SUBTITLE" \
        --mount type=bind,source=$(realpath $TEMPDIR/),target=/local/$TEMPDIR \
        $image \
        /local/$TEMPDIR/pip-freeze-tree.sh /local/$TEMPDIR/$DEPS_LOG_FILE
fi

ls $TEMPDIR
mv $TEMPDIR/$DEPS_LOG_FILE $DEPS_LOG_FILE
