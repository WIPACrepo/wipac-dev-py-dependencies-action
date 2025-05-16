#!/usr/bin/env python3
"""Get the old dependency log file."""
import os
import subprocess
import sys

import requests


def get_file_from_git(branch: str, filename: str) -> str | None:
    try:
        result = subprocess.run(
            ["git", "ls-tree", "-r", "--name-only", f"origin/{branch}"],
            stdout=subprocess.PIPE, text=True, check=True
        )
        for line in result.stdout.splitlines():
            if line.endswith(f"/{filename}"):
                out = subprocess.run(
                    ["git", "show", f"origin/{branch}:{line}"],
                    stdout=subprocess.PIPE, text=True, check=True
                )
                return out.stdout
    except subprocess.CalledProcessError:
        pass
    return None


def get_file_from_release(repo: str, filename: str, token: str) -> str | None:
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    url = f"https://api.github.com/repos/{repo}/releases/latest"
    r = requests.get(url, headers=headers)
    if not r.ok:
        return None

    assets = r.json().get("assets", [])
    for asset in assets:
        if asset.get("name") == filename:
            dl_url = asset.get("browser_download_url")
            dl_r = requests.get(dl_url, headers=headers)
            if dl_r.ok:
                return dl_r.text
    return None


def main():
    if len(sys.argv) != 4:
        print("Usage: get_old_dep_log.py <filename> <default_branch> <github_repo>", file=sys.stderr)
        sys.exit(1)

    fname, branch, repo = sys.argv
    token = os.getenv("GITHUB_TOKEN")
    if not token:
        print("::error::GITHUB_TOKEN is not set", file=sys.stderr)
        sys.exit(1)

    contents = get_file_from_git(branch, fname)
    if contents is None:
        print(f"::notice::{fname} not found in origin/{branch}, trying release asset", file=sys.stderr)
        contents = get_file_from_release(repo, fname, token)
        if contents is None:
            print(f"::notice::No matching release asset found for {fname}", file=sys.stderr)
            sys.exit(2)

    print(contents)


if __name__ == "__main__":
    main()
