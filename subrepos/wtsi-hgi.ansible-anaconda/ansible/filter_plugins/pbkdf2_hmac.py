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
    import hashlib
    HAS_LIB = True
except ImportError:
    HAS_LIB = False

def pbkdf2_hmac(password, salt, length, hashfunc='sha512'):
    '''
    Filter using PKCS#5 password derivation function 2 using HMAC as pseudorandom function 
    to derive a specified amount of key material from a password and salt. 
    Example:
      - debug: msg="{{ password | pbkdf2_hmac('salt', 1024) | base64 }}"
    '''
    if not HAS_LIB:
        raise AnsibleError('You need to install "hashlib" prior to running '
                           'pbkdf2_hmac filter')

    return to_text(hashlib.pbkdf2_hmac(hashfunc, to_bytes(password), to_bytes(salt), 100000, dklen=length))


class FilterModule(object):
    ''' Query filter '''

    def filters(self):
        return {
            'pbkdf2_hmac': pbkdf2_hmac
        }
