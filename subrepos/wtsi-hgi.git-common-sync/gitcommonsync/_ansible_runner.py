from typing import Dict, List

from ansible.executor.task_queue_manager import TaskQueueManager
from ansible.executor.task_result import TaskResult
from ansible.inventory import Inventory
from ansible.parsing.dataloader import DataLoader
from ansible.playbook.play import Play
from ansible.plugins.callback import CallbackBase
from ansible.vars import VariableManager

ANSIBLE_TEMPLATE_MODULE_NAME = "template"
ANSIBLE_RSYNC_MODULE_NAME = "synchronize"


class AnsibleRuntimeException(RuntimeError):
    """
    Exception raised if Ansible encounters a problem at runtime.
    """


class ResultCallbackHandler(CallbackBase):
    """
    Ansible playbook callback handler.
    """
    def __init__(self):
        super().__init__()
        self.results = []

    def v2_runner_on_ok(self, result, **kwargs):
        self.results.append(result)

    def v2_runner_on_failed(self, result, ignore_errors=False):
        self.results.append(result)


class PlaybookOptions:
    """
    Ansible playbook options.
    """
    def __init__(self, *, connection: str="local", module_path: str=None, forks: int=100, become: bool=False,
                 become_method: str=None, become_user: str=None, check: bool=False):
        self.connection = connection
        self.module_path = module_path
        self.forks = forks
        self.become = become
        self.become_method = become_method
        self.become_user = become_user
        self.check = check


def run_ansible(tasks: List[Dict]=None, roles: List[str]=None, variables: Dict[str, str]=None,
                playbook_options: PlaybookOptions=None, results_callback_handler: ResultCallbackHandler=None) \
        -> List[TaskResult]:
    """
    Run the given Ansible tasks or roles with the given options.
    :param tasks: the tasks to run, represented in a list, containing dictionaries. e.g.
    ```
    dict(action=dict(module="file", args=dict(path="/testing", state="directory"), register="testing_created")
    ```
    :param roles: the names of the roles to run
    :param variables: Ansible variables (key-value pairs)
    :param playbook_options: options to use when running Ansible playbook
    :param results_callback_handler: handler for callbacks
    :return: the results of running Ansible
    """
    if variables is None:
        variables = {}
    if playbook_options is None:
        playbook_options = PlaybookOptions()

    variable_manager = VariableManager()
    variable_manager.extra_vars = variables
    loader = DataLoader()
    if results_callback_handler is None:
        results_callback_handler = ResultCallbackHandler()

    inventory = Inventory(loader=loader, variable_manager=variable_manager, host_list=None)
    variable_manager.set_inventory(inventory)

    play_source = dict(
        hosts="localhost",
        gather_facts="no",
    )
    if tasks is not None:
        play_source["tasks"] = tasks
    if roles is not None:
        play_source["roles"] = roles

    play = Play().load(play_source, variable_manager=variable_manager, loader=loader)

    task_queue_manager = None
    try:
        task_queue_manager = TaskQueueManager(
            inventory=inventory,
            variable_manager=variable_manager,
            loader=loader,
            options=playbook_options,
            passwords=dict(),
            stdout_callback=results_callback_handler
        )
        task_queue_manager.run(play)
    finally:
        if task_queue_manager is not None:
            task_queue_manager.cleanup()

    return results_callback_handler.results
