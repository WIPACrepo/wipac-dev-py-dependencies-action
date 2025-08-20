#!/usr/bin/env python3
"""Get the old dependency log file."""
import argparse
import os
import subprocess
import sys
from pathlib import Path

import requests

COMMITS_BACK = 25  # that's probably deep enough


def _log(string: str) -> None:
    print(string, file=sys.stderr)


def _subproc(args: str, stdout=subprocess.DEVNULL) -> subprocess.CompletedProcess:
    _log(f"subprocess: {args=}")
    return subprocess.run(
        args.split(),
        check=True,
        stdout=stdout,
        stderr=subprocess.DEVNULL,
    )


def _subproc_stdout(args: str) -> str:
    res = _subproc(args, stdout=subprocess.PIPE)
    return res.stdout.decode("utf-8").strip()


def get_file_contents_from_git(
    branch: str,
    filename_options: list[str],
    n_commits_old: int = 0,
) -> tuple[Path, str]:
    """Find the file in the branch, optionally at an old commit; return contents"""

    # Resolve the desired commit hash
    if n_commits_old == 0:
        commit_ref = f"origin/{branch}"
    else:
        _log(f"-> fetching origin/{branch} ({n_commits_old=})")
        # fetch, then find commit ref
        _subproc(f"git fetch origin {branch} --deepen {n_commits_old + 1}")
        commit_ref = _subproc_stdout(
            f"git rev-list --max-count=1 origin/{branch} --skip={n_commits_old}"
        )
        if not commit_ref:
            _log(f"fetched commit ref got '{commit_ref}', skipping...")
            raise FileNotFoundError()
    _log(f"using {commit_ref=}")

    # List all files in that commit ref
    ls_tree = _subproc_stdout(f"git ls-tree -r --name-only {commit_ref}").splitlines()

    # Search for a matching file
    for line in ls_tree:
        if any(Path(line).name == o for o in filename_options):
            return Path(line), _subproc_stdout(f"git show {commit_ref}:{line}")

    _log(f"-> did not find file {ls_tree=}")
    raise FileNotFoundError()


def write_file_from_git_history(
    branch: str,
    filename_options: list[str],
    write_to: Path,
) -> bool:
    """Find the file in the branch, going back one commit at a time.

    Then write its contents to `write_to`.
    """
    for n in range(COMMITS_BACK):
        try:
            fpath, contents = get_file_contents_from_git(
                branch, filename_options, n_commits_old=n
            )
        except FileNotFoundError:
            continue
        else:
            _log(f"::notice::found file {fpath=} in '{branch}'")
            write_to.write_text(contents)
            return True

    _log(f"file not found in previous {COMMITS_BACK} commits {filename_options=}")
    return False


def write_file_from_gh_release(
    repo: str, filename: str, token: str, write_to: Path
) -> bool:
    """Find the file in the github release, then write it to `write_to`."""

    # get the gh release
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github.v3+json",
    }
    url = f"https://api.github.com/repos/{repo}/releases/latest"
    r = requests.get(url, headers=headers)
    if not r.ok:
        return False

    # find the file
    contents = None
    for asset in r.json().get("assets", []):
        _log(f"{asset=}")
        if asset.get("name") == filename:
            dl_url = asset.get("browser_download_url")
            dl_r = requests.get(dl_url, headers=headers)
            if dl_r.ok:
                contents = dl_r.text
                break

    # write it
    if contents is not None:
        _log(f"::notice::found file '{filename}' in latest github release assets")
        write_to.write_text(contents)
        return True
    else:
        _log(f"file not found in latest github release assets '{filename}'")
        return False


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
        _log("::error::GITHUB_TOKEN is not set")
        sys.exit(1)

    # look for file in github releases
    if write_file_from_gh_release(args.repo, args.filename, token, args.dest):
        return

    # back-up plan:
    # -- look for files in git. starting with latest commit
    filename_options = [
        # match by basename, however old versions named the file w/o the 'py-' prefix
        f"{args.filename}",
        f"{args.filename.removeprefix('py-')}",
    ]
    if write_file_from_git_history(args.branch, filename_options, args.dest):
        return

    # back-up back-up plan:
    # -- if this is a docker container, then it may match an older py-dep naming format
    if args.filename.startswith("py-dependencies-docker-"):
        if write_file_from_git_history(
            args.branch, ["dependencies-from-Dockerfile.log"], args.dest
        ):
            return

    # not to be found
    _log(
        f"::warning::could not find an existing '{args.filename}' -- assuming it is new"
    )


if __name__ == "__main__":
    main()
