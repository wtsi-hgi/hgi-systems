# Copyright (c) 2018 Genome Research Ltd.
#
# Author: Joshua C. Randall <jcrandall@alum.mit.edu>
#
# This file is part of hgi-systems.
#
# hgi-systems is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.
#

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import json

DOCUMENTATION = '''
    callback: hgi_per_host_lock
    type: aggregate
    short_description: HGI plugin for locking each host
    description:
      - Obtains a lock for each inventory hostname
    requirements:
      - whitelist in configuration
'''

from ansible.plugins.callback import CallbackBase


class CallbackModule(CallbackBase):
    """
    Get a per-host lock before proceeding with each task
    """
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'aggregate'
    CALLBACK_NAME = 'hgi_per_host_lock'
    CALLBACK_NEEDS_WHITELIST = False

    def __init__(self, *args, **kwargs):
        super(CallbackModule, self).__init__(*args, **kwargs)
        self.task = None
        self.play = None

    def v2_playbook_on_start(self, playbook):
        self._display.display("%s: v2_playbook_on_start: play-name=%s hosts=%s" % (CallbackModule.CALLBACK_NAME, playbook.get_name(), playbook.hosts))

    # def v2_on_any(self, *args, **kwargs):
    #     play = getattr(self.play, 'name', None)
    #     task = self.task
    #     self._display.display("hgi_per_host_lock: v2_on_any play [%s] task [%s] args: [%s] kwargs: [%s]" % (play, task, json.dumps(args), json.dumps(kwargs)))
    #
    # def v2_playbook_on_task_start(self, task, is_conditional):
    #     self._display.display("hgi_per_host_lock: v2_playbook_on_task_start task start %s" % (task))
    #     self.task = task
    #
    # def v2_playbook_on_handler_task_start(self, task):
    #     self._display.display("hgi_per_host_lock: v2_playbook_on_handler_task_start task start %s" % (task))
    #     self.task = task
    #
    # def v2_runner_on_failed(self, result, ignore_errors=False):
    #     host = result._host.get_name()
    #     self._display.display("hgi_per_host_lock: v2_runner_on_failed runner failed on host %s" % (host))
    #
    # def v2_runner_on_ok(self, result):
    #     host = result._host.get_name()
    #     self._display.display("hgi_per_host_lock: v2_runner_on_ok runner ok on host %s" % (host))
    #
    # def v2_runner_on_skipped(self, result):
    #     host = result._host.get_name()
    #     self._display.display("hgi_per_host_lock: v2_runner_on_skipped runner skipped on host %s" % (host))
    #
    # def v2_runner_on_unreachable(self, result):
    #     host = result._host.get_name()
    #     self._display.display("hgi_per_host_lock: v2_runner_on_unreachable runner unreachable on host %s" % (host))

