# wipac-dev-py-dependencies-action
GitHub Action Package for Automating Python-Package Dependency Management


## Overview
This GitHub Action creates 1+ `dependencies*.log`-type file(s) for documenting dependency versions (ex: `dependencies.log`, `dependencies-dev.log`, `dependencies-from-Dockerfile.log`, etc.). These files are similar to `requirements*.txt`-type files, with the distinct difference that `dependencies*.log`-type files are not intended to be the source of truth, but rather, a reflection of the tested environment(s). If dependency-version pinning is wanted, it should be done by the user in the `setup.cfg`/`pyproject.toml` file.

### Details
The root directory's `dependencies.log` is overwritten/updated (by way of `pip freeze` + [`pipdeptree`](https://pypi.org/project/pipdeptree/)) along with dedicated `dependencies-EXTRA.log` files for each package "extra".

_However,_ if there is a `Dockerfile` present at the root of the target repo, a similar process occurs but _within_ a container built from the `Dockerfile`. This log file is named `dependencies-from-Dockerfile.log`. If there are other `Dockerfile`s present (ex: `Dockerfile-foo`), additional files are generated using the appropriate name (ex: `dependencies-from-Dockerfile-foo.log`).

### Example File
        ```
        #
        # This file was autogenerated by WIPACrepo/wipac-dev-py-setup-action
        #   from `pip install .`
        #   using Python 3.10.
        #
        ########################################################################
        #  pip freeze
        ########################################################################
        certifi==2023.7.22
        charset-normalizer==3.3.1
        idna==3.4
        requests==2.31.0
        typing_extensions==4.8.0
        urllib3==2.0.7
        ########################################################################
        #  pipdeptree
        ########################################################################
        pip==23.2.1
        pipdeptree==2.13.0
        setuptools==65.5.1
        wheel==0.41.2
        mock-package
        ├── requests [required: Any, installed: 2.31.0]
        │   ├── certifi [required: >=2017.4.17, installed: 2023.7.22]
        │   ├── charset-normalizer [required: >=2,<4, installed: 3.3.1]
        │   ├── idna [required: >=2.5,<4, installed: 3.4]
        │   └── urllib3 [required: >=1.21.1,<3, installed: 2.0.7]
        └── typing-extensions [required: Any, installed: 4.8.0]
        ```

### Full CI-Workflow: Using Alongside Other GitHub Actions
See https://github.com/WIPACrepo/wipac-dev-py-setup-action#full-ci-workflow-using-alongside-other-github-actions
