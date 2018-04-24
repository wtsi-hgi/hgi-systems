#!/bin/bash

set -euf -o pipefail

build_deps=(
    build-essential
    gcc
    git
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

# Create temporary directory for building
export TMPDIR=$(mktemp -d)

version=2.4.2.0-1
shade_version=1.16.0
gitlabbuildvariables_version=0.2.0
boto3_version=1.4.7
boto_version=2.46.1-hotfix.1
yatadis_version=1.0.0
openstack_info_version=5.5.0
yaosadis_version=2.0.1
python_consul_version=b5600843ae8b31400bc985d110ac97b1e3afbaaf
dnspython_version=1.15.0
consul_lock_version=4.2.0

echo "Installing ansible using pip3 from github..."
if [[ -n $(echo "${version}" | grep "^git-") ]]; then
    revision="$(echo ${version} | perl -p -e 's/git-//')"
else
    revision="v${version}"
fi
echo "Using revision ${revision}"
pip3 install git+https://github.com/ansible/ansible.git@${revision}

echo "Installing shade using pip3..."
pip3 install shade==${shade_version}

echo "Installing boto3 using pip3..."
pip3 install boto3==${boto3_version}

echo "Installing boto using pip3 from github..."
pip3 install git+https://github.com/wtsi-hgi/boto.git@${boto_version}

echo "Installing gitlab-build-variables-manager using pip3 from github..."
pip3 install git+https://github.com/wtsi-hgi/gitlab-build-variables-manager.git@v${gitlabbuildvariables_version}

echo "Installing yatadis using pip3 from github..."
pip3 install git+https://github.com/wtsi-hgi/yatadis.git@${yatadis_version}

echo "Installing openstack-info using pip3 from github..."
pip3 install git+https://github.com/wtsi-hgi/openstack-info.git@${openstack_info_version}

echo "Installing yaosadis using pip3 from github..."
pip3 install git+https://github.com/wtsi-hgi/yaosadis.git@${yaosadis_version}

echo "Installing python-consul using pip3..."
#pip3 install python-consul==${python_consul_version}
pip3 install git+https://github.com/wtsi-hgi/python-consul.git@${python_consul_version}

echo "Installing dnspython using pip3..."
pip3 install dnspython==${dnspython_version}

echo "Installing consul-lock using pip3 from github..."
pip3 install git+https://github.com/wtsi-hgi/consul-lock.git@${consul_lock_version}

echo "removing $TMPDIR"
cd
rm -rf "${TMPDIR}"

XDG_CACHE_HOME=${XDG_CACHE_HOME:-${HOME}/.cache}
echo "Clearing XDG_CACHE_HOME: ${XDG_CACHE_HOME}"
rm -rf "${XDG_CACHE_HOME}"

echo "Removing build deps: ${build_deps_remove[@]}"
apt-get remove -y ${build_deps_remove[@]}
apt-get autoremove -y

echo "Clearing apt cache"
rm -rf /var/lib/apt/lists/*

