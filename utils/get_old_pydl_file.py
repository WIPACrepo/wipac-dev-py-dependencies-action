#!/usr/bin/env python3
"""Get the old dependency log file."""
import argparse
import logging
import os
import subprocess
import sys
from pathlib import Path

import requests

LOGGER = logging.getLogger()  # use root


def _subproc(args: str, stdout=subprocess.DEVNULL) -> subprocess.CompletedProcess:
    LOGGER.info(f"subprocess: {args=}")
    return subprocess.run(
        args.split(),
        check=True,
        stdout=stdout,
        stderr=subprocess.DEVNULL,
    )


def _subproc_stdout(args: str) -> str:
    res = _subproc(args, stdout=subprocess.PIPE)
    return res.stdout.decode("utf-8").strip()


def get_file_from_git(branch: str, filename: str, n_commits_old: int = 0) -> str | None:
    """Find the file in the branch, optionally at an old commit."""

    # Resolve the desired commit hash
    if n_commits_old == 0:
        commit_ref = f"origin/{branch}"
    else:
        LOGGER.info(f"-> fetching origin/{branch} ({n_commits_old=})")
        # fetch, then find commit ref
        _subproc(f"git fetch origin {branch} --deepen {n_commits_old + 1}")
        commit_ref = _subproc_stdout(
            f"git rev-list --max-count=1 origin/{branch} --skip={n_commits_old}"
        )

    # List all files in that commit ref
    ls_tree = _subproc_stdout(f"git ls-tree -r --name-only {commit_ref}")

    # Search for a matching file
    for line in ls_tree.splitlines():
        if any(
            line.endswith(m)
            # match by basename, however old versions named the file w/o the 'py-' prefix
            for m in [f"/{filename}", f"/{filename.removeprefix('py-')}"]
        ):
            return _subproc_stdout(f"git show {commit_ref}:{line}")

    LOGGER.info("-> did not find file")
    return None


def get_file_from_release(repo: str, filename: str, token: str) -> str | None:
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github.v3+json",
    }
    url = f"https://api.github.com/repos/{repo}/releases/latest"
    r = requests.get(url, headers=headers)
    if not r.ok:
        return None

    for asset in r.json().get("assets", []):
        LOGGER.info(f"{asset=}")
        if asset.get("name") == filename:
            dl_url = asset.get("browser_download_url")
            dl_r = requests.get(dl_url, headers=headers)
            if dl_r.ok:
                return dl_r.text
    return None


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Get an old dependency log file from git or release."
    )
    parser.add_argument(
        "filename",
        help="The file name to retrieve.",
    )
    parser.add_argument(
        "--branch",
        required=True,
        help="The default branch to check.",
    )
    parser.add_argument(
        "--repo",
        required=True,
        help="GitHub repository (e.g. owner/repo).",
    )
    parser.add_argument(
        "--dest",
        type=Path,
        required=True,
        help="The file path to write the found file to.",
    )
    args = parser.parse_args()

    token = os.getenv("GITHUB_TOKEN")
    if not token:
        print("::error::GITHUB_TOKEN is not set", file=sys.stderr)
        sys.exit(1)

    # look for file
    from_release = get_file_from_release(args.repo, args.filename, token)
    if from_release:
        print(
            f"::notice::found file '{args.filename}' in release asset",
            file=sys.stderr,
        )
        args.dest.write_text(from_release)
        return

    # back-up plan: look for files in git -- start with latest commit (n=0)
    for n in range(25):  # that's probably deep enough
        from_git = get_file_from_git(args.branch, args.filename, n_commits_old=n)
        if from_git:
            print(
                f"::notice::found file '{args.filename}' in '{args.branch}'",
                file=sys.stderr,
            )
            args.dest.write_text(from_git)
            return

    # not to be found
    print(f"::notice::could not find file '{args.filename}'")
    sys.exit(2)


if __name__ == "__main__":
    LOGGER.setLevel(logging.DEBUG)
    main()
