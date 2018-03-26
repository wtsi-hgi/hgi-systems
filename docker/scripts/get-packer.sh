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

echo "getting gox"
go get github.com/mitchellh/gox

echo "getting packer source"
mkdir -p $GOPATH/src/github.com/hashicorp
cd $GOPATH/src/github.com/hashicorp
# FIXME revert to building from hashicorp released version 
# instead of wtsi-hgi fix/ansible-inventory-dir once the fix 
# is merged: https://github.com/hashicorp/packer/pull/6065
git clone https://github.com/wtsi-hgi/packer
cd packer
git checkout fix/ansible-inventory-dir

echo "building packer"
export XC_ARCH="amd64"
export XC_OS="linux"
export PACKER_DEV=1
/bin/bash scripts/build.sh || (echo "failed to build packer"; exit 1)
cp ${GOPATH}/bin/packer /usr/local/bin/

echo "removing $TMPDIR"
cd
rm -rf ${TMPDIR}

