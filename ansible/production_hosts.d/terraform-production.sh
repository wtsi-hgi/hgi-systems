#!/bin/bash

export TF_ANSIBLE_GROUPS_TEMPLATE='{{ ["all", "tf_provider_"+provider] | join(",") }}'
export TF_STATE=../../terraform/production/terraform.tfstate
../../subrepos/yatadis/yatadis.py $@
