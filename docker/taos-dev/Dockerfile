FROM mercury/taos

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         vim \
         emacs24-nox \
         less \
         man \
         jq \
         sudo \
         curl \
         dnsutils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/AdrianSchneider/jsonfui/releases/download/1.2.6/jsonfui-linux-1.2.6 > /usr/bin/jsonfui \
    && chmod 0755 /usr/bin/jsonfui

RUN git clone --depth=1 https://github.com/ingydotnet/git-subrepo /usr/local/src/git-subrepo \
    && echo "source /usr/local/src/git-subrepo/.rc" >> ~/.bashrc

CMD ["bash"]
