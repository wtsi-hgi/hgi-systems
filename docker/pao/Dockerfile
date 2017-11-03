FROM ubuntu:16.04

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
         python3-dev \
         python3-pip \
         python3-setuptools \
         python3-wheel \
    && rm -rf /var/lib/apt/lists/*

# Build Go
ENV GOLANG_VERSION 1.7.4
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_DOWNLOAD_SHA256 47fda42e46b4c3ec93fa5d4d4cc6a748aa3f9411a2a2b7e08e3a6d80d753ec8b
RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
    && echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - \
    && tar -C /usr/local -xzf golang.tar.gz \
    && rm golang.tar.gz
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH

# Build packer
ENV PACKER_DEV=1
RUN go get github.com/mitchellh/gox
RUN cd $GOPATH/src/github.com/mitchellh && \
    git clone https://github.com/mitchellh/packer.git && \
    cd packer && \
    git checkout v0.12.3
WORKDIR $GOPATH/src/github.com/mitchellh/packer
RUN /bin/bash scripts/build.sh

# Install OpenStack client (PyPi version is much more up-to-date than that install via apt!)
RUN pip3 install python-openstackclient==3.9.0

# Install glancecp
#RUN cd /tmp \
#    && git clone https://github.com/wtsi-hgi/openstack-tools.git \
#    && cd openstack-tools \
#    && python3 setup.py install

# XXX: something above has installed `warlock==1.3.0`. The requirements of the below are:
# warlock!=1.3.0,<2,>=1.0.1 (from python-glanceclient>=2.5.0->python-openstackclient>=3.3.0->python-ironicclient>=0.10.0->shade==1.16.0)
# For whatever reason (a bug or due to install of packages with apt-get?), there are a number of files missing when pip deletes
# warlock, before installing `warlock==1.2.0`. Safely deleting warlock now.
RUN pip3 uninstall -y warlock || true

# Install ansible and friends using pip3
RUN pip3 install --no-cache-dir git+https://github.com/ansible/ansible.git@v2.3.0.0-1 \
    && pip3 install --no-cache-dir shade==1.16.0 \
    && pip3 install --no-cache-dir git+https://github.com/wtsi-hgi/gitlab-build-variables-manager.git@v1.0.0 \
    && pip3 install --no-cache-dir git+https://github.com/wtsi-hgi/boto.git@2.46.1-hotfix.1 \
    && pip3 install --no-cache-dir git+https://github.com/wtsi-hgi/yatadis.git@0.4.1

# Set workdir and entrypoint
WORKDIR /tmp
ENTRYPOINT []
