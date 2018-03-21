FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

# Install git-push prerequisites
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         apt-utils \
         software-properties-common \
    && apt-get install -y --no-install-recommends \
         bash \
         coreutils \
         git \
         openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Install python-gitlab
COPY scripts/get-python-gitlab.sh /tmp/get-python-gitlab.sh
RUN /tmp/get-python-gitlab.sh && rm /tmp/get-python-gitlab.sh

ADD gitlab-ci-git-push/git-push /usr/local/bin/

# Install GRL CA
ADD gitlab-ci-git-push/grl-ca.pem /etc/ssl/certs/grl-ca.pem
RUN \
  ln -s /etc/ssl/certs/grl-ca.pem /usr/lib/ssl/certs/91155464.0 && \
  cat /etc/ssl/certs/grl-ca.pem >> /etc/ssl/certs/ca-certificates.crt
