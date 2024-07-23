ARG PYTHON=3.12

FROM python:${PYTHON}

ENV GITHUB_ACTION_PATH="/gha/"

CMD ["/bin/bash", "$GITHUB_ACTION_PATH/action.sh"]
