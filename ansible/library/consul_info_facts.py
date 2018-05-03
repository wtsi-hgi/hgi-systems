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
module: consul_info_facts
short_description: Sets facts based on `consul info` output
description:
  - Sets facts regarding consul cluster from a particular agent's consul info output.
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
- name: Gather consul info facts
  consul_info_facts: consul_bin="/usr/local/bin/consul"
"""

from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils._text import to_bytes
import subprocess
import re


def main():
    module = AnsibleModule(
        argument_spec={
            "consul_bin": {"required": False, "default": "/usr/bin/consul", "type": "str"},
            "mgmt_token": {"required": False, "default": "", "type": "str"},
        },
        supports_check_mode=True
    )
    consul_info_cmdline = [module.params["consul_bin"], "info"]
    if module.params["mgmt_token"] != "":
        consul_info_cmdline.extend(["-token=%s" % (module.params["mgmt_token"])])
    try:
        consul_info_process = subprocess.run(consul_info_cmdline, shell=False, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as cpe:
        module.fail_json(msg="consul info exited with status %s with stdout %s and stderr %s" % (cpe.returncode, cpe.stdout, cpe.stderr))
    except OSError as ose:
        module.fail_json(msg="error running consul command: %s" % (ose))

    # parse consul info output
    consul_info = {}
    section = None
    section_re = re.compile('^\s*(.*?):\s*$')
    keyval_re = re.compile('^\s*(.*?)\s*=\s*(.*?)\s*$')
    for line in consul_info_process.stdout.decode('utf-8').splitlines():
        m = section_re.search(line)
        if m:
            section = m.group(1)
            consul_info[section] = {}
            continue
        m = keyval_re.search(line)
        if m:
            k = m.group(1)
            v = m.group(2)
            if section:
                consul_info[section][k] = v
            else:
                consul_info[k] = v
        else:
            module.fail_json(msg="failed to parse line of consul info output: %s" % (line))

    module.exit_json(changed=False, message="Facts set from consul info", consul_info=consul_info)


if __name__ == "__main__":
    main()
