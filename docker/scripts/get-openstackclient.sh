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

build_deps_remove=$(comm -23 <(for dep in "${build_deps[@]}"; do echo "${dep}"; done | sort) <(dpkg -l | awk '{print $2}' | cut -f1 -d: | sort))

echo "Installing prereqs and build deps: ${build_deps[@]} ${deps[@]}"
apt-get update && apt-get install -y --no-install-recommends ${build_deps[@]} ${deps[@]}

echo "Installing python-openstackclient using pip3"
pip3 install python-openstackclient==3.9.0

echo "Removing build deps: ${build_deps_remove[@]}"
apt-get remove -y ${build_deps_remove[@]}
apt-get autoremove -y

echo "Clearing apt cache"
rm -rf /var/lib/apt/lists/*
