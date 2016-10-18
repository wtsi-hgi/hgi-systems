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

def main():
    # Create module with the following parameters
    module = AnsibleModule(argument_spec={
        'host':     {'required': False, 'type': 'str', 'default': 'http://localhost:5984'},
        'username': {'required': True,  'type': 'str'},
        'password': {'required': True,  'type': 'str'}
    })

    # TODO
    # GET $HOST/_config/admins/$USERNAME (basic auth: $USERNAME:$PASSWORD)
    # 200: Successful (noop)
    # 401: PUT $HOST/_config/admins/$USERNAME (payload: $PASSWORD)
    #      200: Successful
    #      401: Fail

if __name__ == "__main__":
    main()
