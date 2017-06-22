set -euf -o pipefail

if [[ -z "${INFOBLOX_USERNAME+x}" ]]; then
    >&2 echo "INFOBLOX_USERNAME must be set!"
    exit 1
fi
if [[ -z "${INFOBLOX_PASSWORD+x}" ]]; then
    >&2 echo "INFOBLOX_PASSWORD must be set!"
    exit 1
fi
if [[ -z "${INFOBLOX_HOST+x}" ]]; then
    >&2 echo "INFOBLOX_HOST must be set!"
    exit 1
fi
export INFOBLOX_SSLVERIFY=false

