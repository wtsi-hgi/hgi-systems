FROM python:3.6

ENV TOOLS_DIRECTORY=/investigator

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        jq \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir "${TOOLS_DIRECTORY}"
WORKDIR "${TOOLS_DIRECTORY}"

ADD requirements.txt requirements.txt
RUN pip install --disable-pip-version-check -r requirements.txt

ADD * ./

CMD []
