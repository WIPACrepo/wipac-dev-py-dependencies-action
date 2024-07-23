ARG PYTHON=3.12

FROM python:${PYTHON}

CMD ["/bin/bash", "$GITHUB_ACTION_PATH/action.sh"]
