#!/bin/bash
set -x  # turn on debugging
set -e

########################################################################
#
# Build dependencies.log and
# generate dependencies-*.log for each extras_require
#
########################################################################


# get all extras
VARIANTS_LIST=$(python3 $GITHUB_ACTION_PATH/utils/list_extras.py .)
VARIANTS_LIST="- $(echo $VARIANTS_LIST)" # "-" signifies regular package
echo $VARIANTS_LIST

TEMPDIR=$(mktemp -d)
trap 'rm -rf "$TEMPDIR"' EXIT

# generate dependencies-*.log for each extras_require (each in a subproc)
for variant in $VARIANTS_LIST; do
  echo

  if [[ $variant == "-" ]]; then  # regular package (not an extra)
    pip_install_pkg="."
    dockerfile="$TEMPDIR/Dockerfile"
    DEPS_LOG_FILE="dependencies.log"
  else
    pip_install_pkg=".[$variant]"
    dockerfile="$TEMPDIR/Dockerfile_$variant"
    DEPS_LOG_FILE="dependencies-${variant}.log"
  fi

  cat << EOF >> $dockerfile
FROM python:$PACKAGE_MAX_PYTHON_VERSION
COPY . .
RUN pip install --no-cache-dir $pip_install_pkg
CMD []
EOF

  $GITHUB_ACTION_PATH/generate_dep_logs/gen-deps.sh \
    $(realpath $dockerfile) \
    $DEPS_LOG_FILE \
    "from \`pip install $pip_install_pkg\`" \
    &

done
echo

# wait for all subprocs
for _ in $VARIANTS_LIST; do
  wait -n
done
