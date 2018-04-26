FROM mercury/taos

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         vim \
         emacs \
         less \
         man \
         jq \
         sudo \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth=1 https://github.com/ingydotnet/git-subrepo /usr/local/src/git-subrepo \
    && echo "source /usr/local/src/git-subrepo/.rc" >> ~/.bashrc

CMD ["bash"]

RUN echo "FIXME: I'm a comment to get this to rebuild"