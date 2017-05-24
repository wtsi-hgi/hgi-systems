FROM ubuntu:16.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python-openstackclient \
        s3cmd \
        git \
        ruby \
        python3 \
    && rm -rf /var/lib/apt/lists/*

# Set workdir and entrypoint
WORKDIR /tmp
ENTRYPOINT []
