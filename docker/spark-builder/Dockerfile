# spark-builder
FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         bash \
         git \
         openjdk-8-jdk \
         python \
         python-pip \
         curl \
         r-base-dev \
         maven \
         libopenblas-base \
         libatlas3-base \
         libnetlib-java \
    && rm -rf /var/lib/apt/lists/*

RUN pip install j2cli

RUN curl -L "https://raw.githubusercontent.com/wtsi-hgi/tarbomb-disposal/master/tbd" > /usr/bin/tbd

# Set workdir and entrypoint
WORKDIR /tmp
ENTRYPOINT []
