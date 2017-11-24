# Copyright (c) 2017 Genome Research Ltd.
#
# Author: Joshua C. Randall <jcrandall@alum.mit.edu>
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

from ansible.module_utils._text import to_text, to_bytes

try:
    import binascii
    HAS_LIB = True
except ImportError:
    HAS_LIB = False

def hex(data):
    '''
    Filter binary data to a hex string.
    Example:
      - debug: msg="{{ data | hex }}"
    '''
    if not HAS_LIB:
        raise AnsibleError('You need to install "binascii" prior to running '
                           'hex filter')

    return to_text(binascii.hexlify(to_bytes(data)))


class FilterModule(object):
    ''' Query filter '''

    def filters(self):
        return {
            'hex': hex
        }
