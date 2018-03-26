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
import string
import math
 
BASE36 = string.digits+string.ascii_lowercase

def b36encode(data):
    data = to_bytes(data, errors='surrogate_or_strict')
    size = math.ceil(math.log(2**(len(data)*8), 36))
    num = int.from_bytes(data, byteorder='big', signed=False)
    base36 = ''
    while num > 0:
        num, r = divmod(num, 36)
        base36 += BASE36[r]
    if len(base36) < size:
        base36 = (BASE36[0] * (size-len(base36))) + base36
    return to_text(base36)

def b36decode(string):
    return to_text(int(to_bytes(string, errors='surrogate_or_strict'), 36))

class FilterModule(object):
    ''' Query filter '''

    def filters(self):
        return {
            'b36decode': b36decode,
            'b36encode': b36encode,
        }
