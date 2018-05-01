#!/bin/bash

set -euf -o pipefail

build_deps=(
    build-essential
    git
    curl
    zip
)

deps=(
    ca-certificates
)

build_deps_remove=$(comm -23 <(for dep in "${build_deps[@]}"; do echo "${dep}"; done | sort) <(dpkg -l | awk '{print $2}' | cut -f1 -d: | sort))

echo "Installing prereqs and build deps: ${build_deps[@]} ${deps[@]}"
apt-get update && apt-get install -y --no-install-recommends ${build_deps[@]} ${deps[@]}

# Create temporary directory for building
export TMPDIR=$(mktemp -d)

# Install go 1.9 to build terraform
export GOLANG_VERSION=1.9
export GOLANG_DOWNLOAD_URL=https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
export GOLANG_DOWNLOAD_SHA256=d70eadefce8e160638a9a6db97f7192d8463069ab33138893ad3bf31b0650a79
cd "${TMPDIR}"
curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz
echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - || (echo "failed to verify download hash"; exit 1)
echo "Verified hash, expanding archive into ${TMPDIR}/local"
mkdir -p "${TMPDIR}/local"
tar -C "${TMPDIR}/local" -xzf golang.tar.gz

# Setup go environment in tmpdir
echo "setting up temporary go environment in $TMPDIR"
export GOPATH="${TMPDIR}/go"
export PATH="${GOPATH}/bin:${TMPDIR}/local/go/bin:$PATH"
mkdir -p "$GOPATH/src" "$GOPATH/bin"
chmod -R 777 "$GOPATH"
cd ${GOPATH}

echo "getting terraform source"
mkdir -p $GOPATH/src/github.com/hashicorp
cd $GOPATH/src/github.com/hashicorp
git clone https://github.com/hashicorp/terraform
cd terraform
git checkout v0.11.2

echo "building terraform"
export XC_ARCH="amd64"
export XC_OS="linux"
/bin/bash scripts/build.sh || (echo "failed to build terraform"; exit 1)
cp ${GOPATH}/bin/terraform /usr/local/bin/

echo "building terraform-provider-infoblox"
mkdir -p $GOPATH/src/github.com/prudhvitella
cd $GOPATH/src/github.com/prudhvitella
git clone https://github.com/prudhvitella/terraform-provider-infoblox.git
cd terraform-provider-infoblox
git checkout 9cec6f57
make bin
cp ${GOPATH}/bin/terraform-provider-infoblox /usr/local/bin/

echo "removing $TMPDIR"
cd
rm -rf ${TMPDIR}

XDG_CACHE_HOME=${XDG_CACHE_HOME:-${HOME}/.cache}
echo "Clearing XDG_CACHE_HOME: ${XDG_CACHE_HOME}"
rm -rf "${XDG_CACHE_HOME}"

echo "Removing build deps: ${build_deps_remove[@]}"
apt-get remove -y ${build_deps_remove[@]}
apt-get autoremove -y

echo "Clearing apt cache"
rm -rf /var/lib/apt/lists/*

echo "setting up terraform plugins"
echo "providers {
  infoblox = \"/usr/local/bin/terraform-provider-infoblox\"
}" > ~/.terraformrc
