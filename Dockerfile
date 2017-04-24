FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

# Install Go prerequisite, ansible, openstack, and s3 packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         apt-utils \
         software-properties-common \
    && apt-get install -y --no-install-recommends \
         ansible \
         bash \
         curl \
         git \
         graphviz \
         openssh-client \
         python3-openstackclient \
         python3-setuptools \
         s3cmd \
         wget \
         unzip \
    && rm -rf /var/lib/apt/lists/*

# Install go
COPY get-go.sh /tmp/get-go.sh
RUN /tmp/get-go.sh && rm /tmp/get-go.sh

# Setup go environment
ENV PATH /usr/local/go/bin:$PATH

# Install terraform
COPY get-terraform.sh /tmp/get-terraform.sh
RUN /tmp/get-terraform.sh && rm /tmp/get-terraform.sh

# Install yatadis 
RUN cd /tmp \
    && git clone https://github.com/wtsi-hgi/yatadis.git \
    && cd yatadis \
    && git checkout 0.4.0 \
    && python3 setup.py install \
    && cd \
    && rm -rf /tmp/yatadis

# Set workdir and entrypoint
WORKDIR /tmp
ENTRYPOINT []
