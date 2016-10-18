#!/usr/bin/python

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
#
# file: library/couchdb_admin.py

DOCUMENTATION = """
---
module: couchdb_admin
short_description: Set up CouchDB admin users
description:
  - Creates (if not already) an admin user with the given username and password
author:
  - Christopher Harrison <ch12@sanger.ac.uk>
"""

from ansible.module_utils.basic import AnsibleModule

def request(method, url, payload=None, basic_auth=None):
    """
    Make an HTTP request

    @param   method      HTTP method (e.g., GET, PUT, etc.)
    @param   url         URL to request
    @param   payload     Request payload
    @param   basic_auth  Basic authentication tuple
    @return  Response status code, body tuple
    """
    # TODO
    pass

def wtf(module, status, body):
    """ Failure return """
    module.fail_json(msg="Failure - HTTP %s: %s" % (status, body))

if __name__ == "__main__":
    # Create module with the following parameters
    module = AnsibleModule(argument_spec={
        'base_url': {'required': False, 'type': 'str', 'default': 'http://localhost:5984'},
        'username': {'required': True,  'type': 'str'},
        'password': {'required': True,  'type': 'str'}
    })

    url = '%s/_config/admins/%s' % (module.params['base_url'], module.params['username'])
    basic_auth = module.params['username'], module.params['password']

    status, body = request('GET', url)
    if status == 404:
        # Admin Party: Create first user
        status, body = request('PUT', url, payload='"%s"' % module.params['password'])
        if status == 200:
            module.exit_json(changed=True, message="User created successfully")
        else:
            wtf(module, status, body)

    elif status == 401:
        # Users already exist, so let's hope we're recreating ourselves
        status, body = request('PUT', url, payload='"%s"' % module.params['password'], basic_auth=basic_auth)
        if status == 200:
            module.exit_json(changed=False, message="User already exists")
        elif status == 401:
            module.fail.json(msg="Cannot authenticate to create user")
        else:
            wtf(module, status, body)

    else:
        wtf(module, status, body)
