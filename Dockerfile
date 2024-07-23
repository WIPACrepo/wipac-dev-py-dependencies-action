ARG PYTHON=3.12

FROM python:${PYTHON}

ENV GITHUB_ACTION_PATH="/gha/"
WORKDIR $GITHUB_ACTION_PATH
COPY . .

RUN apt-get update
RUN pip3 install -r $GITHUB_ACTION_PATH/requirements.txt

# go
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash", "action.sh"]
