#!/bin/bash

set -euf -o pipefail

export GOLANG_VERSION=1.8.1
export GOLANG_DOWNLOAD_URL=https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
export GOLANG_DOWNLOAD_SHA256=a579ab19d5237e263254f1eac5352efcf1d70b9dacadb6d6bb12b0911ede8994

export TMPDIR=$(mktemp -d)

cd "${TMPDIR}"

curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz
echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - || (echo "failed to verify download hash"; exit 1)

echo "Verified hash, expanding archive into /usr/local"
tar -C /usr/local -xzf golang.tar.gz \

echo "Removing archive" 
rm golang.tar.gz

cd
rm -rf "${TMPDIR}"
