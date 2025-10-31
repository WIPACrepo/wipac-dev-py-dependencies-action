#!/usr/bin/env python3
"""
Compute the project's max supported Python (major.minor) using wipac-dev-tools.
Prints the version to stdout for capture in the calling shell step.
"""

from wipac_dev_tools import semver_parser_tools


def main() -> int:
    top_python = semver_parser_tools.get_latest_py3_release()
    all_matches = semver_parser_tools.list_all_majmin_versions(
        major=top_python[0],
        semver_range=semver_parser_tools.get_py_semver_range_for_project(),
        max_minor=top_python[1],
    )
    latest = max(all_matches)
    print(f"{latest[0]}.{latest[1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
