ARG PYTHON=3.12

FROM python:${PYTHON}

ENV GITHUB_ACTION_PATH="/gha/"
WORKDIR $GITHUB_ACTION_PATH
COPY . .

# to startup docker daemon
RUN touch /var/log/dockerd.log

RUN apt-get update
RUN pip3 install -r $GITHUB_ACTION_PATH/requirements.txt

# go
ENTRYPOINT ["/gha/entrypoint.sh"]
CMD ["/bin/bash", "action.sh"]
