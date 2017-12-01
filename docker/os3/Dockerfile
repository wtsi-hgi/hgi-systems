FROM ubuntu:16.04

RUN apt-get -q=2 update \
    && apt-get -q=2 -y --no-install-recommends install \
        python-openstackclient \
        s3cmd \
        git \
        ruby \
        python3 \
        python3-pip \
        ssh \
        curl \
        bzip2 \
        gzip \
        xorriso \
	xz-utils \
    && apt-get autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install python-gitlab

# Set workdir and entrypoint
WORKDIR /tmp
ENTRYPOINT []
