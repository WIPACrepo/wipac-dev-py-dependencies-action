ARG PYTHON=3.12

FROM python:${PYTHON}

ENV GITHUB_ACTION_PATH="/gha/"
WORKDIR $GITHUB_ACTION_PATH
COPY . .

RUN sudo apt-get update
RUN pip3 install -r $GITHUB_ACTION_PATH/requirements.txt

CMD ["/bin/bash", "action.sh"]
