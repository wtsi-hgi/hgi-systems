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
  wan:
    description: 
      - Fetch data for WAN members instead of LAN
    required: false
    default: no
  fields_list_output_key:
    description:
      - Output key in which to return a list of fields in the output (default "fields")
  members_output_key:
    description:
      - Output key in which to return a list of dicts (one for each member), each of which contains the fields as map keys.
  by_field_output_key_prefix:
    description:
      - Prefix for an output key in which to return a dict (keyed by field value) of a list (of all members with that field value) of dicts (with the fields for that member).
requirements:
  - "python >= 3.5"
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
            "consul_bin": {"default": "/usr/bin/consul", "type": "str"},
            "mgmt_token": {"default": "", "type": "str"},
            "wan": {"default": "False", "type": "bool"},
            "fields_list_output_key": {"default": "fields", "type": "str"},
            "members_output_key": {"default": "members", "type": "str"},
            "by_field_output_key_prefix": {"default": "members_by_", "type": "str"},
        },
        supports_check_mode=True
    )
    fields_list_output_key = module.params["fields_list_output_key"]
    members_output_key = module.params["members_output_key"]
    by_field_output_key_prefix = module.params["by_field_output_key_prefix"]

    # prepare command line and call consul members
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

    # parse consul members output
    lines = consul_members_process.stdout.decode('utf-8').splitlines()
    header_line = lines[0]
    member_lines = lines[1:]

    # parse header
    column_names = header_line.split()
    column_start_positions = {}
    column_end_positions = {}
    last_end_position = len(header_line)-1
    for column_name in reversed(column_names):
        column_start_position = header_line.find(column_name)
        if column_start_position < 0:
            module.fail_json(msg="consul members output could not be parsed: could not find column for %s" % (column_name))
        column_start_positions[column_name] = column_start_position
        column_end_positions[column_name] = last_end_position
        last_end_position = column_start_position - 1
        
    # initialise output
    consul_members = {}
    consul_members[fields_list_output_key] = column_names
    consul_members[members_output_key] = []

    # parse data
    for member_line in member_lines:
        member_data = {}
        for column_name in column_names:
            column_start_position = column_start_positions[column_name]
            column_end_position = column_end_positions[column_name]
            member_data[column_name] = member_line[column_start_position:column_end_position].strip()
        consul_members[members_output_key].append(member_data)
        for column_name in column_names:
            by_field_output_key = by_field_output_key_prefix + column_name
            if by_field_output_key not in consul_members:
                consul_members[by_field_output_key] = {}
            if member_data[column_name] not in consul_members[by_field_output_key]:
                consul_members[by_field_output_key][member_data[column_name]] = []
            consul_members[by_field_output_key][member_data[column_name]].append(member_data)

    module.exit_json(changed=False, message="Facts set from consul members", consul_members=consul_members)

if __name__ == "__main__":
    main()
