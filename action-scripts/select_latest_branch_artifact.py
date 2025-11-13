#!/usr/bin/env python3
"""Select the newest non-expired 'py-dependencies-logs' artifact for a branch and print JSON only."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from typing import Any


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser(
        description="Pick latest branch artifact (excluding current run)."
    )
    ap.add_argument(
        "--artifacts-json",
        required=True,
    )
    ap.add_argument(
        "--branch",
        required=True,
    )
    ap.add_argument(
        "--exclude-run-id",
        type=int,
        required=True,
    )
    return ap.parse_args()


def _created_at(artifact: dict[str, Any]) -> datetime:
    ts = artifact.get("created_at")
    if not isinstance(ts, str):
        return datetime.min.replace(tzinfo=timezone.utc)
    return datetime.fromisoformat(ts.replace("Z", "+00:00"))


def main() -> int:
    args = parse_args()

    try:
        with open(args.artifacts_json, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:  # noqa: BLE001
        print(f"::error::Failed to read artifacts JSON: {e}", file=sys.stderr)
        return 1

    candidates: list[dict[str, Any]] = []
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

        candidates.append(a)

    if not candidates:
        print(
            "::error::No previous py-dependencies-logs artifact found on this branch.",
            file=sys.stderr,
        )
        return 1

    latest = max(candidates, key=_created_at)
    wr = latest.get("workflow_run") or {}

    # print JSON to stdout; bash consumes it
    json.dump(
        {
            "artifact_name": latest.get("name"),
            "run_id": wr.get("id"),
            "head_sha": wr.get("head_sha"),
        },
        sys.stdout,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
