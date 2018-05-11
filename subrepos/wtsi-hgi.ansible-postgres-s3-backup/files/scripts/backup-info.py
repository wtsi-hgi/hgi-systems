import json
import re
import subprocess
import sys
from argparse import ArgumentParser

import arrow

TO_DELETE_JSON_PARAMETER = "delete"
LATEST_BACKUP_NAME_JSON_PARAMETER = "latest"
NEW_BACKUP_NAME_JSON_PARAMETER = "new"
CURRENT_BACKUP_NAMES_JSON_PARAMETER = "current"

DEFAULT_MAXIMUM_BACKUPS = 10
DEFAULT_BACKUP_NAME_SUFFIX = ""

CURRENT_BACKUPS_POSITIONAL_CLI_PARAMETER = "current-backups"
MAX_NUMBER_OF_BACKUPS_LONG_CLI_PARAMETER = "backups"
BACKUP_NAME_SUFFIX_LONG_CLI_PARAMETER = "suffix"
MC_LOCATION_LONG_CLI_PARAMETER = "mc"
MC_CONFIG_LONG_CLI_PARAMETER = "mc-config"
MC_S3_LOCATION_LONG_CLI_PARAMETER = "mc-s3-location"


class Configuration:
    """
    Configuration to be used.
    """
    def __init__(self, current_backup_names, maximum_number_of_backups, backup_name_suffix, mc_location=None,
                 mc_config=None, mc_s3_location=None):
        self.current_backup_names = current_backup_names
        self.maximum_number_of_backups = maximum_number_of_backups
        self.backup_name_suffix = backup_name_suffix
        self.mc_location = mc_location
        self.mc_config = mc_config
        self.mc_s3_location = mc_s3_location


class Information:
    """
    Information result.
    """
    def __init__(self, new_backup_name, latest_backup, to_delete, current_backup_names):
        self.new_backup_name = new_backup_name
        self.latest_backup_name = latest_backup
        self.to_delete = to_delete
        self.current_backup_names = current_backup_names


def process(configuration):
    """
    Process backup results for the given configuration.
    :param configuration: configuration to process
    :type configuration: Configuration
    :return: results based on the given configuration
    :rtype: Information
    """
    current_backup_names = configuration.current_backup_names
    if configuration.mc_location is not None:
        current_backup_names += _read_backup_names_from_s3(configuration)

    dated_backup_name_map = _create_date_name_map(current_backup_names, configuration.backup_name_suffix)
    sorted_backup_dates = sorted(dated_backup_name_map.keys())
    to_delete = [dated_backup_name_map[x] for x in
                 (sorted_backup_dates[:-configuration.maximum_number_of_backups]
                  if configuration.maximum_number_of_backups > 0 else dated_backup_name_map.keys())]
    latest_backup = dated_backup_name_map[sorted_backup_dates[-1]] if len(dated_backup_name_map) > 0 else None

    new_backup_name = _generate_backup_name(backup_name_suffix=configuration.backup_name_suffix)

    return Information(new_backup_name=new_backup_name, latest_backup=latest_backup, to_delete=to_delete,
                       current_backup_names=current_backup_names)


def main(cli_args):
    """
    Main method.
    :param cli_args: arguments specified on the CLI
    :type cli_args: List[Any]
    """
    configuration = _get_cli_configuration(cli_args)
    output = process(configuration)

    print(json.dumps(_information_to_json(output), sort_keys=True))


def _information_to_json(information):
    """
    Converts the given information to a natively JSON serialisable format.
    :param information: the information to serialise
    :type information: Information
    :return: natively JSON serialisable format
    :rtype: Dict
    """
    return {
        NEW_BACKUP_NAME_JSON_PARAMETER: information.new_backup_name,
        LATEST_BACKUP_NAME_JSON_PARAMETER: information.latest_backup_name,
        TO_DELETE_JSON_PARAMETER: information.to_delete,
        CURRENT_BACKUP_NAMES_JSON_PARAMETER: information.current_backup_names
    }


def _get_cli_configuration(cli_args):
    """
    Gets the CLI configuration from the given CLI arguments.
    :param cli_args: arguments specified on the CLI
    :type cli_args: List[Any]
    :return: configuration implied by the given CLI arguments
    :rtype: Configuration
    """
    parser = ArgumentParser()
    parser.add_argument(CURRENT_BACKUPS_POSITIONAL_CLI_PARAMETER, metavar="current-backup", default=[], nargs="*",
                        type=str, help="name of current backup")
    parser.add_argument("--%s" % MAX_NUMBER_OF_BACKUPS_LONG_CLI_PARAMETER, type=int, default=DEFAULT_MAXIMUM_BACKUPS,
                        help="maximum number of backups to keep")
    parser.add_argument("--%s" % BACKUP_NAME_SUFFIX_LONG_CLI_PARAMETER, type=str, default=DEFAULT_BACKUP_NAME_SUFFIX,
                        help="suffix to add to all backup names")
    parser.add_argument("--%s" % MC_LOCATION_LONG_CLI_PARAMETER, type=str,
                        help="location of minio executable to get current backups from S3")
    parser.add_argument("--%s" % MC_CONFIG_LONG_CLI_PARAMETER, type=str,
                        help="minio configuration")
    parser.add_argument("--%s" % MC_S3_LOCATION_LONG_CLI_PARAMETER, type=str,
                        help="locations of backups in S3")

    arguments = vars(parser.parse_args(cli_args))
    configuration = Configuration(
        current_backup_names=arguments[CURRENT_BACKUPS_POSITIONAL_CLI_PARAMETER],
        maximum_number_of_backups=arguments[MAX_NUMBER_OF_BACKUPS_LONG_CLI_PARAMETER],
        backup_name_suffix=arguments[BACKUP_NAME_SUFFIX_LONG_CLI_PARAMETER],
        mc_location=arguments.get(MC_LOCATION_LONG_CLI_PARAMETER),
        mc_config=arguments.get(MC_CONFIG_LONG_CLI_PARAMETER.replace("-", "_")),
        mc_s3_location=arguments.get(MC_S3_LOCATION_LONG_CLI_PARAMETER.replace("-", "_"))
    )
    return configuration


def _create_date_name_map(backup_names, backup_name_suffix):
    """
    Creates a mapping between backup dates and backup names based on the timestamp in the backup name.
    :param backup_names: names of all backups
    :type backup_names: Iterable[str]
    :param backup_name_suffix: backup name suffix
    :type backup_name_suffix: str
    :return: mapping between backup date and its name
    :rtype: Dict[Arrow, str]
    """
    return {arrow.get(re.sub(r"%s$" % backup_name_suffix, "", backup_name)): backup_name
            for backup_name in backup_names if backup_name.endswith(backup_name_suffix)}


def _generate_backup_name(timestamp=arrow.utcnow(), backup_name_suffix=DEFAULT_BACKUP_NAME_SUFFIX):
    """
    Generates backup name given a timestamp and a suffix.
    :param timestamp: timestamp to associate to the backup
    :type timestamp: Arrow
    :param backup_name_suffix: suffix to append of the backup name
    :type backup_name_suffix: str
    :return: generated backup name
    :rtype: str
    """
    return "%s%s" % (timestamp, backup_name_suffix)


def _read_backup_names_from_s3(configuration):
    """
    Reads names of backups in S3.
    :param configuration: configuration with minio values
    :type configuration: Configuration
    :return: names of backups in S3
    :rtype: List[str]
    """
    if configuration.mc_location is None or configuration.mc_s3_location is None:
        raise ValueError("`mc_location` and `mc_s3_location` must be set to read backup names from S3")

    mc_config_arguments = ["-C", configuration.mc_config] if configuration.mc_config is not None else []
    arguments = [configuration.mc_location] + mc_config_arguments + ["--json", "ls", configuration.mc_s3_location]
    process = subprocess.Popen(arguments, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()
    if process.returncode != 0:
        parsed_stdout = json.loads(stdout.decode("utf-8"))
        if "Object does not exist" in parsed_stdout["error"]["cause"]["message"]:
            return []
        raise RuntimeError(json.dumps(dict(
            stderr=stderr.decode("utf-8"), stdout=parsed_stdout, arguments=arguments)))

    backup_names = []
    for line in stdout.decode("utf-8").split("\n"):
        if line.strip() != "":
            backup_name = json.loads(line)["key"]
            backup_names.append(backup_name)
    return backup_names


if __name__ == "__main__":
    main(sys.argv[1:])
