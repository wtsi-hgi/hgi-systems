FROM mercury/taos

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         vim \
         emacs \
         less \
         man \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/bash"]
