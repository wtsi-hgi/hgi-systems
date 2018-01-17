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

DOCUMENTATION = '''
    callback: hgi_output
    callback_type: stdout
    requirements:
      - set as main display callback
    short_description: Minimal output when all is well, full stack trace to stderr on failure
'''

from ansible import constants as C
from ansible.plugins.callback.default import CallbackModule as CallbackModule_default


class CallbackModule(CallbackModule_default):

    '''
    This is the hgi_output callback plugin, which reuses the default
    callback plugin but sends full error output to stderr on failure 
    and 
    '''

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'stdout'
    CALLBACK_NAME = 'hgi_output'

    def __init__(self):

        self.super_ref = super(CallbackModule, self)
        self.super_ref.__init__()

    def v2_runner_on_skipped(self, result):
        self.outlines = []

    def v2_playbook_item_on_skipped(self, result):
        self.outlines = []

    def v2_runner_item_on_skipped(self, result):
        self.outlines = []

    def v2_playbook_on_task_start(self, task, is_conditional):
        self.outlines = []
        self.outlines.append("TASK [%s]" % task.get_name().strip())
        if self._display.verbosity >= 2:
            path = task.get_path()
            if path:
                self.outlines.append("task path: %s" % path)

    def v2_playbook_item_on_ok(self, result):
        self.display()
        super(CallbackModule, self).v2_playbook_item_on_ok(result)

    def v2_runner_on_ok(self, result):
        self.display()
        super(CallbackModule, self).v2_runner_on_ok(result)

    def display(self):
        if len(self.outlines) == 0:
            return
        (first, rest) = self.outlines[0], self.outlines[1:]
        self._display.banner(first)
        for line in rest:
            self._display.display(line)
        self.outlines = []

    def v2_runner_on_failed(self, result, ignore_errors=False):
        self.display()
        delegated_vars = result._result.get('_ansible_delegated_vars', None)
        self._clean_results(result._result, result._task.action)

        if self._play.strategy == 'free' and self._last_task_banner != result._task._uuid:
            self._print_task_banner(result._task)

        self._handle_exception(result._result, errors_to_stderr=True)
        self._handle_warnings(result._result)

        if result._task.loop and 'results' in result._result:
            self._process_items(result)

        else:
            if delegated_vars:
                self._display.display("fatal: [%s -> %s]: FAILED! => %s" % (result._host.get_name(), delegated_vars['ansible_host'],
                                                                            self._dump_results(result._result)), color=C.COLOR_ERROR,
                                      stderr=True)
            else:
                self._display.display("fatal: [%s]: FAILED! => %s" % (result._host.get_name(), self._dump_results(result._result)),
                                      color=C.COLOR_ERROR, stderr=True)

        if ignore_errors:
            self._display.display("...ignoring", color=C.COLOR_SKIP)

    def _handle_exception(self, result, errors_to_stderr=False):

        if 'exception' in result:
            msg = "An exception occurred during task execution, the full traceback is:\n" + result['exception']
            del result['exception']

            self._display.display(msg, color=C.COLOR_ERROR, stderr=errors_to_stderr)

    def _dump_results(self, result):
        '''Return the text to output for a result.'''

        result['_ansible_verbose_always'] = True

        save = {}
        for key in ['stdout', 'stdout_lines', 'stderr', 'stderr_lines', 'msg', 'module_stdout', 'module_stderr']:
            if key in result:
                save[key] = result.pop(key)

        output = CallbackModule_default._dump_results(self, result)

        for key in ['stdout', 'stderr', 'msg', 'module_stdout', 'module_stderr']:
            if key in save and save[key]:
                output += '\n\n%s:\n\n%s\n' % (key.upper(), save[key])

        for key, value in save.items():
            result[key] = value

        return output
