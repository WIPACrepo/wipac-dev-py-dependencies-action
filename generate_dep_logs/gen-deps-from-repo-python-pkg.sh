#!/bin/bash
set -euo pipefail
sleep 0.1 && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "$(basename "$0")..." && echo
set -ex

########################################################################
#
# Build a PYDL for python package and an additional for each install variant
#
########################################################################

ls $REPO_PATH

# get all extras
VARIANTS_LIST=$(python3 $GITHUB_ACTION_PATH/utils/list_extras.py $REPO_PATH)
VARIANTS_LIST="- $(echo $VARIANTS_LIST)" # "-" signifies regular package
echo $VARIANTS_LIST

TEMPDIR=$(mktemp -d) && trap 'rm -rf "$TEMPDIR"' EXIT

# generate dependencies-*.log for each extras_require (each in a subproc)
for variant in $VARIANTS_LIST; do
    echo

    if [[ $variant == "-" ]]; then # regular package (not an extra)
        pip_install_pkg="."
        dockerfile="$TEMPDIR/Dockerfile"
        PYDL_FNAME="$PYDL_FNAME_PREFIX.log"
    else
        pip_install_pkg=".[$variant]"
        dockerfile="$TEMPDIR/Dockerfile_$variant"
        PYDL_FNAME="$PYDL_FNAME_PREFIX-${variant}.log"
    fi

    # make an ad-hoc dockerfile
    cat <<EOF >>$dockerfile
FROM python:$PACKAGE_MAX_PYTHON_VERSION
COPY . .
RUN pip install --no-cache-dir $pip_install_pkg
CMD []
EOF

    # and build it
    image="gen-$(basename $PYDL_FNAME):local"
    docker build -t $image --file $dockerfile $REPO_PATH

    # generate PYDL!
    $GITHUB_ACTION_PATH/generate_dep_logs/gen-deps-within-container.sh \
        $image \
        "$PYDL_FNAME" \
        "from \`pip install $pip_install_pkg\`" \
        &

done

echo

# wait for all subprocs
for _ in $VARIANTS_LIST; do
    wait -n
done

sleep 0.1 && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
