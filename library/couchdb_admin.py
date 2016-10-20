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

import httplib
import json
from base64 import b64encode
from urlparse import urlparse

from ansible.module_utils.basic import AnsibleModule

class AnsibleModuleWithWTF(AnsibleModule):
    def wtf_json(self, status, headers, body):
        """ Return for unknown failure modes """
        self.fail_json(msg="Unknown failure mode - HTTP %s" % status,
                       meta={"headers": headers, "body": body})

def json_request(method, url, payload=None, basic_auth=None):
    """
    Make an HTTP request under the presumption of JSON payload and response

    @param   method      HTTP method (e.g., GET, PUT, etc.)
    @param   url         URL to request
    @param   payload     Request payload
    @param   basic_auth  Basic authentication tuple (username, password)
    @return  Response status code, header, body JSON tuple
    """
    url_parts = urlparse(url)
    if url_parts.scheme == "http":
        connection = httplib.HTTPConnection(url_parts.netloc)
    elif url_parts.scheme == "https":
        connection = httplib.HTTPConnection(url_parts.netloc)
    else:
        raise httplib.InvalidURL("I don't understand \"%s\"" % url)

    # We expect JSON back
    headers = {"Accept": "application/json"}

    # Serialise JSON payload, if there is one
    if payload and method in ["PUT", "POST"]:
        json_payload = json.dumps(payload)
        headers["Content-Type"] = "application/json"
    else:
        json_payload = None

    # Set authorisation header, if necessary
    if basic_auth:
        basic_hash = b64encode("%s:%s" % basic_auth)
        headers["Authorization"] = "Basic %s" % basic_hash

    connection.request(method, url_parts.path, json_payload, headers)
    res = connection.getresponse()

    # Get response headers
    res_headers = {}
    res_is_json = False
    for h, v in res.getheaders():
        res_headers[h] = v

        if h.lower() == "content-type" and v == "application/json":
            res_is_json = True

    # Deserialise response body, if possible
    res_body = json.loads(res.read()) if res_is_json else res.read()

    return res.status, res_headers, res_body

if __name__ == "__main__":
    # Create module with the following parameters
    module = AnsibleModuleWithWTF(argument_spec={
        "base_url": {"default": "http://localhost:5984", "type": "str"},
        "username": {"required": True,                   "type": "str"},
        "password": {"required": True,                   "type": "str"}
    })

    url = "%s/_config/admins/%s" % (module.params["base_url"], module.params["username"])
    basic_auth = module.params["username"], module.params["password"]

    # FIXME? This is very specific to our use case and it will fail in
    # the general sense when alternative admin users have been defined.
    # Is it worth making this more general? (It would be very easy.)

    status, headers, body = json_request("GET", url)
    if status == 404:
        # Admin Party: Create first user
        status, headers, body = json_request("PUT", url, payload="%s" % module.params["password"])
        if status == 200:
            module.exit_json(changed=True, message="User created successfully")
        else:
            module.wtf_json(status, headers, body)

    elif status == 401:
        # Users already exist, so let's hope we're recreating ourselves
        status, headers, body = json_request("PUT", url, payload="%s" % module.params["password"], basic_auth=basic_auth)
        if status == 200:
            module.exit_json(changed=False, message="User already exists")
        elif status == 401:
            module.fail.json(msg="Cannot authenticate to create user")
        else:
            module.wtf_json(status, headers, body)

    else:
        module.wtf_json(status, headers, body)
