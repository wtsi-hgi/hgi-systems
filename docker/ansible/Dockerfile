FROM ubuntu:17.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python \
        python3.6 \
        python3.6-dev \
        build-essential \
        libssl-dev \
        libffi-dev \
        curl \
        ca-certificates \
        git \
        ssh \
        rsync \
        less \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://bootstrap.pypa.io/get-pip.py | python2 \
    && pip2 --no-cache-dir install setuptools

RUN curl https://bootstrap.pypa.io/get-pip.py | python3.6 \
    && pip3 --no-cache-dir install setuptools

RUN git clone --depth=1 --branch=0.3.1 https://github.com/ingydotnet/git-subrepo.git /tmp/git-subrepo \
    && cd /tmp/git-subrepo \
    && make install \
    && cd - \
    && rm -rf /tmp/git-subrepo

# Pre-install Python requirements (it's rather horrific that the ones in this repository are not used...), which are to
# be updated at runtime
RUN pip2 install -r https://raw.githubusercontent.com/wtsi-hgi/hgi-systems/master/ansible/py2-requirements.txt
RUN pip3 install -r https://raw.githubusercontent.com/wtsi-hgi/hgi-systems/master/ansible/py3-requirements.txt

RUN useradd -m mercury \
    && mkdir /home/mercury/.ssh \
    && mkdir /root/.ssh

ADD ansible.cfg /root/.ansible.cfg
ADD setup.sh /root/setup.sh
RUN chmod 700 /root/setup.sh

VOLUME /hgi-systems
WORKDIR /hgi-systems

ENTRYPOINT ["/root/setup.sh"]
CMD ["bash"]