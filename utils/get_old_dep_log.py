#!/usr/bin/env python3
"""Get the old dependency log file."""
import argparse
import os
import subprocess
import sys

import requests


def get_file_from_git(branch: str, filename: str) -> str | None:
    try:
        result = subprocess.run(
            ["git", "ls-tree", "-r", "--name-only", f"origin/{branch}"],
            stdout=subprocess.PIPE,
            text=True,
            check=True,
        )
        for line in result.stdout.splitlines():
            if line.endswith(f"/{filename}"):
                out = subprocess.run(
                    ["git", "show", f"origin/{branch}:{line}"],
                    stdout=subprocess.PIPE,
                    text=True,
                    check=True,
                )
                return out.stdout
    except subprocess.CalledProcessError:
        pass
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
        if asset.get("name") == filename:
            dl_url = asset.get("browser_download_url")
            dl_r = requests.get(dl_url, headers=headers)
            if dl_r.ok:
                return dl_r.text
    return None


def main():
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

    contents = get_file_from_git(args.branch, args.filename)
    if contents is None:
        print(
            f"::notice::{args.filename} not in origin/{args.branch}, "
            f"trying release asset",
            file=sys.stderr,
        )
        contents = get_file_from_release(args.repo, args.filename, token)
        if contents is None:
            print(
                f"::notice::No matching release asset for {args.filename}",
                file=sys.stderr,
            )
            sys.exit(2)

    print(contents)


if __name__ == "__main__":
    main()
