# pao
FROM python:3.6.2

ENV DEBIAN_FRONTEND noninteractive

# Install Go/Packer prerequisite and openstack packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         apt-utils \
         software-properties-common \
    && apt-get install -y --no-install-recommends \
         bash \
         build-essential \
         curl \
         g++ \
         gcc \
         git \
         libc6-dev \
         libffi-dev \
         libssl-dev \
         make \
         openssh-client \
         pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install ansible
COPY scripts/get-ansible.sh /tmp/get-ansible.sh
RUN /tmp/get-ansible.sh && rm /tmp/get-ansible.sh

# Install go
COPY scripts/get-go.sh /tmp/get-go.sh
RUN /tmp/get-go.sh && rm /tmp/get-go.sh

# Setup go environment
ENV PATH /usr/local/go/bin:$PATH

# Install packer
COPY scripts/get-packer.sh /tmp/get-packer.sh
RUN /tmp/get-packer.sh && rm /tmp/get-packer.sh

# Set workdir and entrypoint
WORKDIR /tmp
ENTRYPOINT []

