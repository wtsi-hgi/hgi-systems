#!/bin/bash

set -euf -o pipefail

# Create temporary directory for building
export TMPDIR=$(mktemp -d)

# Setup go environment in tmpdir
echo "setting up temporary go environment in $TMPDIR"
export GOPATH="${TMPDIR}/go"
export PATH="${GOPATH}/bin:$PATH"
mkdir -p "$GOPATH/src" "$GOPATH/bin"
chmod -R 777 "$GOPATH"
cd ${GOPATH}

echo "getting glance-proxy source"
mkdir -p $GOPATH/src/github.com/wtsi-hgi
cd $GOPATH/src/github.com/wtsi-hgi
git clone https://github.com/wtsi-hgi/glance-proxy
cd glance-proxy
git checkout v1.0.0

echo "building glance-proxy"
go get
go install
cp ${GOPATH}/bin/glance-proxy /usr/local/bin/

echo "removing $TMPDIR"
cd
rm -rf ${TMPDIR}

