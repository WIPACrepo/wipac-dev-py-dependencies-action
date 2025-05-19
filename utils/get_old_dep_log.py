#!/usr/bin/env python3
"""Get the old dependency log file."""
import argparse
import os
import subprocess
import sys

import requests


def get_file_from_git(branch: str, filename: str, n_commits_old: int = 0) -> str | None:
    """Find the file in the branch, optionally at an old commit."""

    # Resolve the desired commit hash
    if n_commits_old > 0:
        print(f"-> fetching origin/{branch}", file=sys.stderr)
        subprocess.run(
            ["git", "fetch", "origin", branch, "--deepen", str(n_commits_old + 1)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        commit_ref = subprocess.run(
            [
                "git",
                "rev-list",
                "--max-count=1",
                f"origin/{branch}",
                f"--skip={n_commits_old}",
            ],
            stdout=subprocess.PIPE,
            text=True,
            check=True,
        ).stdout.strip()
    else:
        commit_ref = f"origin/{branch}"

    # List all files in that commit
    args = ["git", "ls-tree", "-r", "--name-only", commit_ref]
    print(f"looking at {args}", file=sys.stderr)
    result = subprocess.run(
        args,
        stdout=subprocess.PIPE,
        text=True,
        check=True,
    )

    # Search for a matching file
    for line in result.stdout.splitlines():
        if any(
            line.endswith(m)
            # match by basename, however old versions named the file w/o the 'py-' prefix
            for m in [f"/{filename}", f"/{filename.removeprefix('py-')}"]
        ):
            out = subprocess.run(
                ["git", "show", f"{commit_ref}:{line}"],
                stdout=subprocess.PIPE,
                text=True,
                check=True,
            )
            return out.stdout

    print("-> did not find file", file=sys.stderr)
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
        print(
            f"{asset=}",
            file=sys.stderr,
        )
        if asset.get("name") == filename:
            dl_url = asset.get("browser_download_url")
            dl_r = requests.get(dl_url, headers=headers)
            if dl_r.ok:
                return dl_r.text
    return None


def main() -> str:
    parser = argparse.ArgumentParser(
        description="Get an old dependency log file from git or release."
    )
    parser.add_argument(
        "filename",
        help="The file name to retrieve.",
    )
    parser.add_argument(
        "branch",
        help="The default branch to check.",
    )
    parser.add_argument(
        "repo",
        help="GitHub repository (e.g. owner/repo).",
    )
    args = parser.parse_args()

    token = os.getenv("GITHUB_TOKEN")
    if not token:
        print("::error::GITHUB_TOKEN is not set", file=sys.stderr)
        sys.exit(1)

    # look for file
    contents = get_file_from_release(args.repo, args.filename, token)
    if contents:
        print(
            f"::notice::found file '{args.filename}' in release asset",
            file=sys.stderr,
        )
        return contents

    # back-up plan: look for files in git -- start with latest commit (n=0)
    for n in range(25):  # that's probably deep enough
        contents = get_file_from_git(args.branch, args.filename, n_commits_old=n)
        if contents:
            print(
                f"::notice::found file '{args.filename}' in '{args.branch}'",
                file=sys.stderr,
            )
            return contents

    # not to be found
    print(f"::notice::could not find file '{args.filename}'", file=sys.stderr)
    sys.exit(2)


if __name__ == "__main__":
    contents = main()
    print(contents)
