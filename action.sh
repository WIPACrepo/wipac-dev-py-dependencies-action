#!/bin/bash
set -euo pipefail
sleep 0.1 && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "$(basename "$0")..." && echo
set -e

########################################################################
#
# Generate dependencies-*.log file(s)
#
########################################################################

ls $REPO_PATH

########################################################################

# env vars
export PACKAGE_NAME=$(python3 $GITHUB_ACTION_PATH/utils/get_package_name.py .)

########################################################################

# grab local copy to avoid path mangling -- replace when https://github.com/WIPACrepo/wipac-dev-py-dependencies-action/issues/6
pip install requests semantic-version
temp_dir=$(mktemp -d) && cd $temp_dir && trap 'rm -rf $temp_dir' EXIT
wget https://raw.githubusercontent.com/WIPACrepo/wipac-dev-tools/main/wipac_dev_tools/semver_parser_tools.py -O $temp_dir/semver_parser_tools_local.py

# get python3 version (max) -- copied from https://github.com/WIPACrepo/wipac-dev-py-versions-action/blob/main/action.yml
export PACKAGE_MAX_PYTHON_VERSION=$(python -c '
import os, re
import semver_parser_tools_local as semver_parser_tools

repo_path = os.environ["REPO_PATH"]

semver_range = ""
if os.path.isfile(f"{repo_path}/pyproject.toml"):
    # ex: requires-python = ">=3.8, <3.13"
    pat = re.compile(r"requires-python = \"(?P<semver_range>[^\"]+)\"$")
    with open(f"{repo_path}/pyproject.toml") as f:
        for line in f:
            if m := pat.match(line):
                semver_range = m.group("semver_range")
    if not semver_range:
        raise Exception("could not find `requires-python` entry in pyproject.toml")
elif os.path.isfile(f"{repo_path}/setup.cfg"):
    # ex: python_requires = >=3.8, <3.13
    pat = re.compile(r"python_requires = (?P<semver_range>.+)$")
    with open(f"{repo_path}/setup.cfg") as f:
        for line in f:
            if m := pat.match(line):
                semver_range = m.group("semver_range")
    if not semver_range:
        raise Exception("could not find `python_requires` entry in setup.cfg")
else:
    raise Exception("could not find pyproject.toml nor setup.cfg")

top_python = semver_parser_tools.get_latest_py3_release()
all_matches = semver_parser_tools.list_all_majmin_versions(
  major=top_python[0],
  semver_range=semver_range,
  max_minor=top_python[1],
)
print(f"{max(all_matches)[0]}.{max(all_matches)[1]}")
')

echo "$PACKAGE_MAX_PYTHON_VERSION"

########################################################################
# Dockerfile / docker image logic

# Detect if user supplied image(s)
IMAGES_TO_DEP=$(docker images | awk -v pat="$DOCKER_TAG_TO_DEP" '$2==pat' | awk -F ' ' '{print $1":"$2}')

# Check if any images exist
if [ -z "$IMAGES_TO_DEP" ]; then
    n_images=0
else
    n_images=$(echo "$IMAGES_TO_DEP" | wc -l)
fi

# Validate that each ignored Dockerfile actually exists
IFS=',' read -r -a ignore_paths <<<"$DOCKERFILE_IGNORE_PATHS"
for i in "${!ignore_paths[@]}"; do
    ignore_paths["$i"]="$REPO_PATH/${ignore_paths[$i]}"
done
echo "Ignoring the following Dockerfiles:"
for file in "${ignore_paths[@]}"; do
    if [[ -n $file ]]; then
        echo "  - $file"
        if [[ ! -f $file ]]; then
            echo "::error::Ignored Dockerfile '$file' does not exist."
            exit 1
        fi
    fi
done

# Count non-ignored Dockerfiles in repo
find_cmd=(find "$REPO_PATH" -name "Dockerfile*")
# -> append exclusion arguments
for path in "${ignore_paths[@]}"; do
    if [[ -n $path ]]; then
        find_cmd+=(-not -path "$path")
    fi
done
echo "Searching for non-ignored Dockerfiles..."
mapfile -t dockerfiles < <("${find_cmd[@]}")
# -> echo found Dockerfiles
if [[ ${#dockerfiles[@]} -gt 0 ]]; then
    echo "Found the following Dockerfiles:"
    for df in "${dockerfiles[@]}"; do
        echo "  - $df"
    done
else
    echo "No Dockerfiles found."
fi
n_good_dockerfiles=${#dockerfiles[@]}

# Compare counts, is everyone accounted for?
if ((n_good_dockerfiles > n_images)); then
    echo "::error::$n_good_dockerfiles 'Dockerfile*' file(s) found but $n_images pre-built Docker image(s) with tag='$DOCKER_TAG_TO_DEP' were provided"
    exit 1
fi

########################################################################
# generate

if [ -n "$IMAGES_TO_DEP" ]; then
    # from Dockerfile(s)...
    export IMAGES_TO_DEP
    "$GITHUB_ACTION_PATH"/generate_dep_logs/gen-deps-from-user-docker-images.sh
else
    # from python package...
    "$GITHUB_ACTION_PATH"/generate_dep_logs/gen-deps-from-repo-python-pkg.sh
fi

sleep 0.1 && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
