#!/bin/bash
set -euo pipefail

####################################################################################
# Dump artifact contents to console
####################################################################################

echo "now: $(date -u +"%Y-%m-%dT%H:%M:%S.%3N")"

echo "##[group]dumping artifact contents"

ARTIFACTS_DIR="${1:-artifacts}"

if [[ ! -d $ARTIFACTS_DIR ]]; then
    echo "::error::No artifacts directory found at $ARTIFACTS_DIR"
    exit 1
fi

shopt -s nullglob
for file in "$ARTIFACTS_DIR"/*; do
    echo " "
    echo " "
    echo " "
    echo "====> $file <$(printf '=%.0s' $(seq 1 $((72 - 7 - ${#file}))))"
    echo " "

    if [[ -s $file ]]; then
        cat "$file" || echo "(unreadable or binary)"
    else
        echo "(empty file)"
    fi
done

echo "##[endgroup]"
