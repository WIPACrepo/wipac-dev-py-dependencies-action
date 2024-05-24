"""Print the package name (metadata section) for a python project."""

import argparse
import configparser
from pathlib import Path

import toml


def _get_name_pyproject_toml(pyproject_toml: Path) -> str:
    """Get package name."""
    with open(pyproject_toml) as f:
        toml_dict = toml.load(f)
    try:
        return toml_dict["project"]["name"]
    except KeyError:
        return "UNKNOWN"


def _get_name_setup_cfg(setup_cfg_file: Path) -> str:
    """Get package name."""
    cfg = configparser.ConfigParser()
    cfg.read(setup_cfg_file)
    try:
        return cfg["metadata"]["name"]
    except KeyError:
        return "UNKNOWN"


def get_name(project_dir: Path) -> str:
    """Get package name."""
    if "pyproject.toml" in [f.name for f in project_dir.iterdir()]:
        return _get_name_pyproject_toml(project_dir.joinpath("pyproject.toml"))
    elif "setup.cfg" in [f.name for f in project_dir.iterdir()]:
        return _get_name_setup_cfg(project_dir.joinpath("setup.cfg"))
    else:
        raise FileNotFoundError(
            f"Could not find pyproject.toml or setup.cfg in {project_dir}"
        )


if __name__ == "__main__":

    def _type_dir(arg: str) -> Path:
        fpath = Path(arg)
        if not fpath.exists():
            raise FileNotFoundError(f"Directory not found: {arg}")
        elif not fpath.is_dir():
            raise NotADirectoryError(arg)
        else:
            return fpath

    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "project_dir",
        type=_type_dir,
        help="python project dir",
    )
    args = parser.parse_args()

    name = get_name(args.project_dir)
    print(name)
