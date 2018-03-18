#!/bin/bash

set -euf -o pipefail

build_deps=(
    python3-pip
)

deps=(
    python3
    python3-setuptools
)

echo "Installing prereqs and build deps: ${build_deps[@]} ${deps[@]}"
apt-get update && apt-get install -y --no-install-recommends ${build_deps[@]} ${deps[@]}

echo "Installing python-gitlab using pip3"
pip3 install python-gitlab

echo "Removing build deps: ${build_deps[@]}"
apt-get remove -y ${build_deps[@]}
apt-get autoremove -y

echo "Clearing apt cache"
rm -rf /var/lib/apt/lists/*
