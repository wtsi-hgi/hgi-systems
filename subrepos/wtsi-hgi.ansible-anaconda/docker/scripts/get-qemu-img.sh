#!/bin/bash

set -euf -o pipefail

build_deps=(
    gcc
    build-essential
    pkg-config
    git
    openssl
    ca-certificates
    libglib2.0-dev
    libfdt-dev
    zlib1g-dev
    libbz2-dev 
    libcurl4-gnutls-dev
    libpixman-1-dev
    librbd-dev
    librdmacm-dev
    libsasl2-dev
    libsnappy-dev
    libssh2-1-dev
    liblzo2-dev
    xfslibs-dev
)

deps=(
    python
    libglib2.0-0
    libfdt1
    zlib1g
    libbz2-1.0
    libcurl3-gnutls
    libpixman-1-0
    librbd1
    librdmacm1
    libsasl2-2
    libsnappy1v5
    libssh2-1
    liblzo2-2
)

build_deps_remove=$(comm -23 <(for dep in "${build_deps[@]}"; do echo "${dep}"; done | sort) <(dpkg -l | awk '{print $2}' | cut -f1 -d: | sort))

echo "Installing prereqs and build deps: ${build_deps[@]} ${deps[@]}"
apt-get update && apt-get install -y --no-install-recommends ${build_deps[@]} ${deps[@]}

# Create temporary directory for building
export TMPDIR=$(mktemp -d)

echo "getting qemu source"
cd "${TMPDIR}"
git clone https://github.com/qemu/qemu.git
cd qemu
git checkout v2.11.1

echo "building qemu"
mkdir build
cd build
../configure --enable-tools --disable-system
make
cp ./qemu-img /usr/local/bin/

echo "removing $TMPDIR"
cd
rm -rf ${TMPDIR}

echo "Removing build deps: ${build_deps_remove[@]}"
apt-get remove -y ${build_deps_remove[@]}
apt-get autoremove -y

echo "Clearing apt cache"
rm -rf /var/lib/apt/lists/*

