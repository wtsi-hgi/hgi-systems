#!/bin/bash

set -euf -o pipefail

build_deps=(
    gcc
    python3-pip
    python3-wheel
    python3-dev
    libssl-dev
)

deps=(
    python3
    python3-setuptools
    libssl1.0.0
)

echo "Installing prereqs and build deps: ${build_deps[@]} ${deps[@]}"
apt-get update && apt-get install -y --no-install-recommends ${build_deps[@]} ${deps[@]}

echo "Installing python-openstackclient using pip3"
pip3 install python-openstackclient==3.9.0

echo "Removing build deps: ${build_deps[@]}"
apt-get remove -y ${build_deps[@]}
apt-get autoremove -y

echo "Clearing apt cache"
rm -rf /var/lib/apt/lists/*
