#!/usr/bin/env python3
"""
Select the newest non-expired artifact named 'py-dependencies-logs' for a given branch,
excluding a specific workflow run ID. Writes 'artifact_name=...' to $GITHUB_OUTPUT.
"""

import argparse
import json
import os
from datetime import datetime
from typing import Any


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser(
        description="Pick latest branch artifact (excluding current run)."
    )
    ap.add_argument(
        "--artifacts-json",
        required=True,
        help="Path to artifacts.json from GitHub API.",
    )
    ap.add_argument(
        "--branch",
        required=True,
        help="Branch name to filter on.",
    )
    ap.add_argument(
        "--exclude-run-id",
        type=int,
        required=True,
        help="Workflow run ID to exclude.",
    )
    ap.add_argument(
        "--github-output",
        default=os.environ.get("GITHUB_OUTPUT", ""),
        help="Path to $GITHUB_OUTPUT.",
    )
    return ap.parse_args()


def _created_at(artifact: dict[str, Any]) -> datetime:
    return datetime.fromisoformat(artifact["created_at"].replace("Z", "+00:00"))


def main() -> int:
    args = parse_args()

    try:
        with open(args.artifacts_json, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:  # noqa: BLE001
        print(f"::error::Failed to read artifacts JSON: {e}")
        return 1

    artifacts = []
    for a in data.get("artifacts", []):
        if a.get("expired"):
            continue
        wr = a.get("workflow_run") or {}
        if wr.get("head_branch") != args.branch:
            continue
        try:
            if int(wr.get("id", 0)) == args.exclude_run_id:
                continue
        except Exception:
            continue
        artifacts.append(a)

    if not artifacts:
        print(
            "::error::No previous py-dependencies-logs artifact found on this branch."
        )
        return 1

    latest = max(artifacts, key=_created_at)
    print(
        f"::notice::Using artifact id={latest.get('id')} "
        f"(run {latest.get('workflow_run', {}).get('id')}) "
        f"created_at={latest.get('created_at')}"
    )

    out_line = f"artifact_name={latest.get('name')}\n"
    if not args.github_output:
        print("::warning::GITHUB_OUTPUT not set; printing output instead:")
        print(out_line, end="")
    else:
        with open(args.github_output, "a", encoding="utf-8") as out:
            out.write(out_line)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
