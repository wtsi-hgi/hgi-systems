set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/../common.sh"

ensureSet S3_ACCESS_KEY S3_SECRET_KEY S3_HOST

if [[ -z "${S3_HOST_BUCKET+x}" ]]; then
    export S3_HOST_BUCKET="%(bucket)s.${S3_HOST}"
fi

cat <<EOF > ~/.s3cfg
[default]
access_key = ${S3_ACCESS_KEY}
check_ssl_certificate = True
check_ssl_hostname = True
host_base = ${S3_HOST}
host_bucket = ${S3_HOST_BUCKET}
secret_key = ${S3_SECRET_KEY}
use_https = True
EOF

