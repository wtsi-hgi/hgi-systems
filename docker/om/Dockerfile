FROM ubuntu:16.04

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
         python3-dev \
         python3-pip \
         python3-setuptools \
         qemu \
         ruby \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install python-gitlab

RUN curl -L -o /usr/local/bin/mc https://dl.minio.io/client/mc/release/linux-amd64/mc && \
    chmod a+x /usr/local/bin/mc

# Install go
COPY scripts/get-go.sh /tmp/get-go.sh
RUN /tmp/get-go.sh && rm /tmp/get-go.sh

# Setup go environment
ENV PATH /usr/local/go/bin:$PATH

# Install openstack client (PyPi version is much more up-to-date than that install via apt!)
RUN pip3 install python-openstackclient==3.9.0

# Install glance-proxy
COPY scripts/get-glance-proxy.sh /tmp/get-glance-proxy.sh
RUN /tmp/get-glance-proxy.sh && rm /tmp/get-glance-proxy.sh

# Set workdir and entrypoint
WORKDIR /tmp
ENTRYPOINT []

