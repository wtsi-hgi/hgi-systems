#!/bin/bash

set -euf -o pipefail

build_deps=(
    python3-pip
)

deps=(
    python3
    python3-setuptools
)

build_deps_remove=$(comm -23 <(echo ${build_deps[@]} | sort) <(dpkg -l | awk '{print $2}' | cut -f1 -d: | sort))

echo "Installing prereqs and build deps: ${build_deps[@]} ${deps[@]}"
apt-get update && apt-get install -y --no-install-recommends ${build_deps[@]} ${deps[@]}

echo "Installing python-gitlab using pip3"
pip3 install python-gitlab

echo "Removing build deps: ${build_deps_remove[@]}"
apt-get remove -y ${build_deps_remove[@]}
apt-get autoremove -y

echo "Clearing apt cache"
rm -rf /var/lib/apt/lists/*
