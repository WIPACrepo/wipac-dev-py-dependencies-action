ARG PYTHON=3.12

FROM python:${PYTHON}

CMD ["/bin/bash", "action.sh"]
