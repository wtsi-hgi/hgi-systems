#!/usr/bin/env bash
set -eu -o pipefail

EXECUTABLE_NAME="$(basename "$0")"
SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPOSITORY_ROOT="$(cd ${SCRIPT_DIRECTORY} && git rev-parse --show-toplevel)"

dwgsConfig=~/.dwgs-config.yml
pullDockerImage=1
dwgsLocation=$(which docker-with-gitlab-secrets || echo "docker-with-gitlab-secrets not found on PATH")
envSettings=()

usage() {
  cat <<-EOF
	Usage: $(basename ${EXECUTABLE_NAME}) [options]

	Start hgi-systems development container

	options:
	-c	docker-with-gitlab-secrets configuration file location [default: ${dwgsConfig}]
	-d	docker-with-gitlab-secrets executable location [default: ${dwgsLocation}]
	-n	Set to not pull latest taos-dev Docker image on start [default: 0]
	-e      Extra environment variable to set in container [can be repeated]
	EOF
}

while getopts "c:d:ne:h" opt; do
	case ${opt} in
		c)
			>&2 dwgsConfig="${OPTARG}"
			;;
		d)
			>&2 dwgsLocation="${OPTARG}"
			;;
		n)
			>&2 pullDockerImage=0
			;;
                e)      
                        >&2 envSettings+=(${OPTARG})
                        ;;
		h)
			usage
			exit 0
			;;
		\?)
			usage
			exit 1
			;;
		:)
			usage
			exit 1
			;;
	esac
done
shift $((OPTIND -1))

if [[ "${pullDockerImage}" -eq 1 ]]; then
	>&2 echo "Updating taos-dev docker image..."
	docker pull mercury/taos-dev > /dev/null
fi

GIT_GLOBAL_IGNORE="$(git config --global core.excludesfile || echo /dev/null)"

"${dwgsLocation}" --dwgs-config "${dwgsConfig}" --dwgs-project "hgi-systems" \
	run --rm -it \
		-e HOST_USER_ID="$(id -u)" -e HOST_USER_NAME="$(id -nu)" -e HOST_USER_GROUP_ID="$(id -g)" -e HOST_USER_GROUP_NAME="$(id -ng)" \
                $(for envSetting in ${envSettings[@]}; do echo -n "-e ${envSetting} "; done) \
		-v "${REPOSITORY_ROOT}:/mnt/host/hgi-systems" -w /mnt/host/hgi-systems \
		$(test -f ~/.gitconfig && echo '-v ~/.gitconfig:/mnt/host/.gitconfig:ro') \
                $(test -f "${GIT_GLOBAL_IGNORE}" && echo '-v "'${GIT_GLOBAL_IGNORE}':/mnt/host/.gitignore_global:ro"') \
		$(test -f ~/.ssh/id_rsa && echo '-v ~/.ssh/id_rsa:/mnt/host/id_rsa:ro') \
		-v "${SCRIPT_DIRECTORY}/ssh-config:/mnt/host/ssh-config:ro" \
		-v "${SCRIPT_DIRECTORY}/help.sh:/mnt/host/help.sh:ro" \
		mercury/taos-dev "/mnt/host/hgi-systems/${SCRIPT_DIRECTORY#"$REPOSITORY_ROOT"}/_setup.sh"
