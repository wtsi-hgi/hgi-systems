#!/usr/bin/env bash
set -eu -o pipefail

export PROJECT_ROOT=$PWD
PYTHONPATH=. coverage run -m unittest discover -v -s gitcommonsync/tests

coverage run setup.py install

# Awful bit of munging to map coverage to the module in the project package
sed -i -e "s#[^\"]*ansible_module.py#${PROJECT_ROOT}\/gitcommonsync\/ansible_module.py#g" .coverage*

coverage combine -a
coverage report
