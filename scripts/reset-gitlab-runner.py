import os
import sys
from typing import List, Set, Iterable

from paramiko import SSHClient, AutoAddPolicy

from simpleopenstack.factories import OpenstackInstanceManagerFactory
from simpleopenstack.managers import OpenstackInstanceManager
from simpleopenstack.os_managers import RealOpenstackConnector

ERROR_STATE = "Error"
HOST = "gitlab-runner-delta-hgi-ci-01.hgi.sanger.ac.uk"
USERNAME = "mercury"


def execute(ssh_client: SSHClient, command: str, sudo: bool=True) -> List[str]:
    _, stdout, stderr = ssh_client.exec_command(f"{'sudo -i ' if sudo else ''}{command}")

    status_code = stdout.channel.recv_exit_status()
    if status_code != 0:
        raise RuntimeError(
            f"Remote execution resulted in a non-zero status code: {status_code}. Error: {stderr.read()}")

    return stdout.readlines()


def get_docker_machines(ssh_client: SSHClient) -> Set[str]:
    stdout = execute(ssh_client, "docker-machine ls --format '{{.Name}}\t{{.State}}'")

    machines: Set[str] = set()
    for line in stdout:
        identifier, status = line.strip().split("\t")
        machines.add(identifier.strip())

    return machines


def remove_os_runner_instances(instance_manager: OpenstackInstanceManager) -> Set[str]:
    instances = instance_manager.get_all()
    removed: Set[str] = set()
    for instance in instances:
        if instance.name.startswith("runner-"):
            print(f"Removing instance: {instance.name} (name indicates spawned runner)", file=sys.stderr)
            instance_manager.delete(item=instance)
            removed.add(instance)
    return removed


def remove_docker_machines(ssh_client: SSHClient, machine_names: Iterable[str]):
    for machine_name in machine_names:
        print(f"Removing Docker machine: {machine_name}", file=sys.stderr)
        execute(ssh_client, f"docker-machine rm -f {machine_name}")


def main():
    ssh_client = SSHClient()
    ssh_client.set_missing_host_key_policy(AutoAddPolicy())
    ssh_client.connect(HOST, username=USERNAME)
    instance_manager = OpenstackInstanceManagerFactory(
        RealOpenstackConnector(os.environ["OS_AUTH_URL"], os.environ["OS_TENANT_NAME"], os.environ["OS_USERNAME"],
                               os.environ["OS_PASSWORD"])
    ).create()

    execute(ssh_client, "gitlab-runner stop")
    docker_machines = get_docker_machines(ssh_client)
    remove_docker_machines(ssh_client, docker_machines)
    remove_os_runner_instances(instance_manager)
    execute(ssh_client, "gitlab-runner start")
    print(execute(ssh_client, "gitlab-runner status")[0].strip(), file=sys.stderr)


if __name__ == "__main__":
    main()
