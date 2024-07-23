#!/bin/bash
set -x  # turn on debugging
set -e


cd /repo/
ls


# env vars
export PACKAGE_NAME=$(python3 $GITHUB_ACTION_PATH/utils/get_package_name.py .)


# remove any old ones, then regenerate only what's needed
rm dependencies*.log || true


# grab local copy to avoid path mangling -- replace when https://github.com/WIPACrepo/wipac-dev-py-dependencies-action/issues/6
pip install requests semantic-version
wget https://raw.githubusercontent.com/WIPACrepo/wipac-dev-tools/main/wipac_dev_tools/semver_parser_tools.py -O semver_parser_tools_local.py

# get python3 version (max) -- copied from https://github.com/WIPACrepo/wipac-dev-py-versions-action/blob/main/action.yml
export PACKAGE_MAX_PYTHON_VERSION=$(python -c '
import os, re
import semver_parser_tools_local as semver_parser_tools

semver_range = ""
if os.path.isfile("pyproject.toml"):
    # ex: requires-python = ">=3.8, <3.13"
    pat = re.compile(r"requires-python = \"(?P<semver_range>[^\"]+)\"$")
    with open("pyproject.toml") as f:
        for line in f:
            if m := pat.match(line):
                semver_range = m.group("semver_range")
    if not semver_range:
        raise Exception("could not find `requires-python` entry in pyproject.toml")
elif os.path.isfile("setup.cfg"):
    # ex: python_requires = >=3.8, <3.13
    pat = re.compile(r"python_requires = (?P<semver_range>.+)$")
    with open("setup.cfg") as f:
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

echo $PACKAGE_MAX_PYTHON_VERSION


# Build
if [ -f ./Dockerfile ]; then
  # from Dockerfile(s)...
  $GITHUB_ACTION_PATH/generate_dep_logs/gen-deps-from-repo-dockerfiles.sh
else
  # from setup.cfg...
  $GITHUB_ACTION_PATH/generate_dep_logs/gen-deps-from-repo-python-pkg.sh
fi
