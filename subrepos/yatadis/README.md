Yet Another Terraform Ansible Dynamic Inventory Script (yatadis)
================================================================

An [ansible dynamic inventory](https://docs.ansible.com/ansible/intro_dynamic_inventory.html) script which takes [Terraform][terraform] state files as input.

In contrast with other Terraform ansible dynamic inventory scripts, this one aims to be configurable to match your environment. It implements this using [Jinja2][jinja2] templates to specify how Terraform resource attributes should be mapped onto ansible inventory name, group, and host_vars.

Basic usage
-----------

Ansible calls dynamic inventory scripts with either the `--list` or `--host` option, but no additional arguments. For that reason, yatadis accepts all of its options from environment variables:
* TF_STATE: a path to a local terraform.tfstate file (default: terraform.tfstate in the current directory)
* TF_ANSIBLE_INVENTORY_NAME_TEMPLATE: a [Jinja2][jinja2] template string that is applied to each Terraform resource to generate the ansible inventory name (default: `{{ resource_name }}` which is the resource name (TYPE+NAME) from Terraform is guaranteed to be unique).
* TF_ANSIBLE_GROUPS_TEMPLATE: a [Jinja2][jinja2] template string that is applied to each Terraform resource to generate a comma-delimited list of ansible groups to which the resource should belong (default: `all` which simply assigns all hosts to the `all` group)
* TF_ANSIBLE_RESOURCE_FILTER_TEMPLATE: a [Jinja2][jinja2] template string that is applied to each Terraform resource and should produce either `True` (to include the resource) or `False` (to exclude the resource). (default: `{{ resource.type in ["aws_instance","azure_instance","clc_server","digitalocean_droplet","google_compute_instance","openstack_compute_instance_v2","softlayer_virtualserver","triton_machine","ucs_service_profile","vsphere_virtual_machine"] }}` which is suitable to limit to instance/machine resources from a variety of Terraform providers.
* TF_ANSIBLE_HOST_VARS_TEMPLATE: a [Jinja2][jinja2] template string that is applied to each Terraform resource and should generate a comma-delimited list of host_var settings in the format `<host_var>=<value>`. (default: a template that will set `host_name` to the IP of the instance/machine as well as setting all resource attributes prefixed with `tf_` - see source code for details).

If you are happy with the defaults, and can arrange for the TF_STATE environment variable to be set to the path to the terraform.tfstate file, then you can just install the yatadis.py script in the ansible inventory directory, make sure it is executable, and that all of the python modules it depends on are installed on the machine on which you run ansible.

In practice, you will most likely want to call yatadis.py from a wrapper script (such as a bash script) that you install into the inventory directory in place of yatadis.py itself and which sets those variables appropriately. For example, here is a simple shell script that simply invokes yatadis.py after setting the path to the terraform.tfstate file:
```
#!/bin/bash

export TF_STATE=/path/to/terraform.tfstate
/path/to/yatadis.py $@
```

You can also specify any of these options on the command line (for testing purposes) - the command line argument is simply the environment variable name without the "TF" prefix:
```
./yatadis.py --list --state /path/to/terraform.tfstate
```

Adding terraform resources to ansible groups
--------------------------------------------

The defaults may be all you need, as all of the primary attributes of each Terraform compute resource will be available in ansible as host_vars with the prefix "tf_", and you can use ansible dynamic groups (using the [group_by module](https://docs.ansible.com/ansible/group_by_module.html) to add hosts to groups based on those host_vars values).

For example, in your site playbook you might add the following:
```
- hosts: all
  tasks:
    - group_by: key=tf_image_{{ tf_image_name }}
```

If you had a resource with a Terraform image_name of `ubuntu_16.04` then it should now be a member of the ansible group `tf_image_ubuntu_16.04`

Alternatively, yatadis can assign hosts to ansible groups for you without the need for ansible's dynamic group functionality.

To do this you will need to set the `TF_ANSIBLE_GROUPS_TEMPLATE` [Jinja2][jinja2] template such that it returns a comma-delimited list of groups to which a host should belong.

For example, to add all instances to a group named after the resource provider and prefixed with `tf_provider_`, you could use the following wrapper script:

```
#!/bin/bash
export TF_ANSIBLE_GROUPS_TEMPLATE='{{ ["all", "tf_provider_"+resource.provider] | join(",") }}'
export TF_STATE=/path/to/terraform.tfstate
/path/to/yatadis.py $@
```


[terraform]: <https://www.terraform.io/>
[jinja2]: <http://jinja.pocoo.org/>
