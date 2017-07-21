import os
import unittest
import warnings

from gitcommonsync._ansible_runner import run_ansible, ResultCallbackHandler

_SCRIPT_LOCATION = os.path.dirname(os.path.realpath(__file__))
_ANSIBLE_TEST_ROLE_NAME = "ansible"


class CustomResultCallbackHandler(ResultCallbackHandler):
    """
    Callback handler that creates sub-tests for each Ansible task.
    """
    def __init__(self, test_case: unittest.TestCase):
        super().__init__()
        self.test_case = test_case

    def v2_runner_on_ok(self, result, **kwargs):
        super().v2_runner_on_ok(result, **kwargs)
        self._on_complete(result)

    def v2_runner_on_failed(self, result, ignore_errors=False):
        super().v2_runner_on_failed(result, ignore_errors=ignore_errors)
        self._on_complete(result)

    def _on_complete(self, result):
        with self.test_case.subTest(task=result.task_name):
            self.test_case.assertFalse(result.is_failed(), result._result)


class TestAnsibleModule(unittest.TestCase):
    """
    Tests runner of the Ansible tests.
    """
    def setUp(self):
        warnings.simplefilter("ignore", ResourceWarning)
        warnings.simplefilter("ignore", DeprecationWarning)

    def test_ansible_execution(self):
        run_ansible(roles=[os.path.join(_SCRIPT_LOCATION, _ANSIBLE_TEST_ROLE_NAME)],
                    results_callback_handler=CustomResultCallbackHandler(self))


if __name__ == "__main__":
    unittest.main()
