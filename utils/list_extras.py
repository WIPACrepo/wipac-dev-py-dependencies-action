"""Print the list of setup/pip extras for python project."""

import argparse
import configparser
from pathlib import Path
from typing import Iterator

import toml


def _iter_extras_pyproject_toml(pyproject_toml: Path) -> Iterator[str]:
    with open(pyproject_toml) as f:
        toml_dict = toml.load(f)
    try:
        yield from list(toml_dict["project"]["optional-dependencies"].keys())
    except KeyError:
        return


def _iter_extras_setup_cfg(setup_cfg_file: Path) -> Iterator[str]:
    cfg = configparser.ConfigParser()
    cfg.read(setup_cfg_file)
    try:
        yield from list(cfg["options.extras_require"].keys())
    except KeyError:
        return


def iter_extras(project_dir: Path) -> Iterator[str]:
    """Yield each extra key."""
    if "pyproject.toml" in [f.name for f in project_dir.iterdir()]:
        yield from _iter_extras_pyproject_toml(project_dir.joinpath("pyproject.toml"))
    elif "setup.cfg" in [f.name for f in project_dir.iterdir()]:
        yield from _iter_extras_setup_cfg(project_dir.joinpath("setup.cfg"))
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

    for extra in iter_extras(args.project_dir):
        print(extra)
