#!/usr/bin/env python3
"""Select the newest non-expired 'py-dependencies-logs' artifact for a branch (excluding a run) and write outputs."""

from __future__ import annotations

import argparse
import json
import os
from datetime import datetime, timezone
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
    ap.add_argument("--branch", required=True, help="Branch name to filter on.")
    ap.add_argument(
        "--exclude-run-id", type=int, required=True, help="Workflow run ID to exclude."
    )
    return ap.parse_args()


def _created_at(artifact: dict[str, Any]) -> datetime:
    ts = artifact.get("created_at")
    if not isinstance(ts, str):
        return datetime.min.replace(tzinfo=timezone.utc)
    return datetime.fromisoformat(ts.replace("Z", "+00:00"))


def _write_output(lines: list[str]) -> None:
    out_path = os.environ.get("GITHUB_OUTPUT")
    if not out_path:
        print("::warning::GITHUB_OUTPUT not set; printing outputs instead:")
        for ln in lines:
            print(ln, end="")
        return
    with open(out_path, "a", encoding="utf-8") as f:
        for ln in lines:
            f.write(ln)


def main() -> int:
    args = parse_args()

    try:
        with open(args.artifacts_json, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:  # noqa: BLE001
        print(f"::error::Failed to read artifacts JSON: {e}")
        return 1

    artifacts: list[dict[str, Any]] = []
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
    wr = latest.get("workflow_run") or {}
    run_id = wr.get("id")
    head_sha = wr.get("head_sha")

    print(
        f"::notice::Using artifact id={latest.get('id')} "
        f"(run {run_id}) created_at={latest.get('created_at')} head_sha={head_sha}"
    )

    _write_output(
        [
            f"artifact_name={latest.get('name')}\n",
            f"run_id={run_id}\n",
            f"head_sha={head_sha}\n",
        ]
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
