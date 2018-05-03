#!/usr/bin/env python3
#!/usr/bin/python
#
# Copyright (c) 2017, 2018 Genome Research Ltd.
#
# Author: Joshua C. Randall <jcrandall@alum.mit.edu>
#
# This file is part of hgi-systems.
#
# hgi-systems is free software: you can redistribute it and/or modify it
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

DOCUMENTATION = """
---
module: consul_members_facts
short_description: Sets facts based on `consul members` output
description:
  - Sets facts regarding consul cluster from a particular agent's consul members output.
author:
  - Joshua C. Randall <jcrandall@alum.mit.edu>
options:
  mgmt_token:
    description:
      - a management token is required to manipulate the acl lists
  consul_bin:
    description: 
      - Path to the consul command
    required: false
requirements:
  - "python >= 3"
"""

EXAMPLES = """
- name: Gather consul members facts
  consul_members_facts: consul_bin="/usr/local/bin/consul"
"""

from ansible.module_utils.basic import AnsibleModule
import subprocess
import re


def main():
    module = AnsibleModule(
        argument_spec={
            "consul_bin": {"required": False, "default": "/usr/bin/consul", type: "bytes"},
            "mgmt_token": {"required": False, "default": "", type: "bytes"},
            "wan": {"required": False, "default": False, type: "boolean"},
        },
        supports_check_mode=True
    )
    consul_members_cmdline = [module.params["consul_bin"], "members"]
    if module.params["mgmt_token"] != "":
        consul_members_cmdline.extend(["-token=%s" % (module.params["mgmt_token"])])
    if module.params["wan"]:
        consul_members_cmdline.extend(["-wan"])
    try:
        consul_members_process = subprocess.run(consul_members_cmdline, shell=False, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as cpe:
        module.fail_json(msg="consul members exited with status %s with stdout %s and stderr %s" % (cpe.returncode, cpe.stdout, cpe.stderr))
    except OSError as ose:
        module.fail_json(msg="error running consul command: %s" % (ose))

    consul_members = {}

    # parse consul members output
    lines = consul_members_process.stdout.decode('utf-8').splitlines()
    header_line = lines[0]
    members_lines = lines[1:]

    # parse header
    column_names = header_line.split()
    column_start_positions = {}
    column_end_positions = {}
    last_end_position = length(header_line)-1
    for column_name in reversed(column_names):
        column_start_position = header_line.find(column_name)
        if column_position < 0:
            module.fail_json(msg="consul members output could not be parsed: could not find column for %s" % (column_name))
        column_start_positions[column_name] = column_start_position
        column_end_positions[column_name] = last_end_position
        last_end_position = column_start_position - 1
    consul_members["fields"] = column_names

    # parse data
    consul_members["data"] = []
    for member_line in member_lines:
        member_data = {}
        for column_name in column_names:
            column_start_position = column_start_positions[column_name]
            column_end_position = column_end_positions[column_name]
            member_data[column_name] = member_line[column_start_position:column_end_position]
        consul_members["data"].push(member_data)

    module.exit_json(changed=False, message="Facts set from consul members", consul_members=consul_members)

if __name__ == "__main__":
    main()
