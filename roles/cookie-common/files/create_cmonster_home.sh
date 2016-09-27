#!/bin/bash

# Copyright (c) 2016 Genome Research Ltd.
#
# Author: Christopher Harrison <ch12@sanger.ac.uk>
#
# This file is part of hgi-ansible.
#
# hgi-ansible is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

set -eu -o pipefail

# Add cmonster to /etc/passwd, if it's not there
# FIXME This assumes, if it is there, the home directory is correct
if ! grep -q '^cmonster' /etc/passwd; then
  getent passwd cmonster \
  | awk -F: 'BEGIN { OFS=":" } { $6="/home/cmonster"; print $0 }' \
  >> /etc/passwd
fi

# Add cmonster to /etc/shadow, if it's not there
# FIXME This assumes, if it is there, it's correct
if ! grep -q '^cmonster' /etc/shadow; then
  echo "cmonster:*:16945:0:99999:7:::" >> /etc/shadow
fi

# Create home directory and chown
mkdir -p /home/cmonster
chown cmonster:hgi /home/cmonster
