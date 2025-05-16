#!/bin/bash
set -euo pipefail
sleep 0.1 && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "$(basename "$0")..." && echo

########################################################################
#
# Generate dependencies-*.log file(s)
#
########################################################################

ls "$REPO_PATH"

########################################################################
# env vars
export PACKAGE_NAME=$(python3 $GITHUB_ACTION_PATH/utils/get_package_name.py .)

########################################################################
# generate

# Detect if user supplied image(s)
IMAGES_TO_DEP=$(docker images | awk -v pat="$DOCKER_TAG_TO_DEP" '$2==pat' | awk -F ' ' '{print $1":"$2}')
if [ -n "$IMAGES_TO_DEP" ]; then
    # from Dockerfile(s)...
    export IMAGES_TO_DEP
    "$GITHUB_ACTION_PATH"/generate_dep_logs/gen-deps-from-user-docker-images.sh
else
    # from python package...
    "$GITHUB_ACTION_PATH"/generate_dep_logs/gen-deps-from-repo-python-pkg.sh
fi

########################################################################

sleep 0.1 && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
