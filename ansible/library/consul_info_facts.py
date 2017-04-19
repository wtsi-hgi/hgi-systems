#!/usr/bin/env python3

DOCUMENTATION = """
---
module: consul_info_facts
short_description: Sets facts based on `consul info` output
description:
  - Sets facts regarding consul cluster from a particular agent's consul info output.
author:
  - Joshua C. Randall <jcrandall@alum.mit.edu>
options:
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

def main():
    module = AnsibleModule(
        argument_spec={
            "consul_bin": {"required": False, "default": "/usr/bin/consul", type: "bytes"},
        },
        supports_check_mode=True
    )

    try:
        consul_info_process = subprocess.run([module.params["consul_bin"], "info"], shell=False, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as cpe:
        module.fail_json(msg="consul info exited with status %s with stdout %s and stderr %s" % (cpe.returncode, cpe.stdout, cpe.stderr))
    except OSError as ose:
        module.fail_json(msg="error running consul command: %s" % (ose))

    # parse consul info output
    consul_info = {}
    section = None
    section_re = re.compile('^\s*(.*):\s*$')
    keyval_re = re.compile('^\s*(.*)\s*=\s*(.*)\s*$')
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

from ansible.module_utils.basic import *
if __name__ == "__main__":
    main()
