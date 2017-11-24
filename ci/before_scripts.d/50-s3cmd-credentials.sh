set -euf -o pipefail

if [[ -z "${S3_ACCESS_KEY+x}" ]]; then
    >&2 echo "S3_ACCESS_KEY must be set!"
    exit 1
fi
if [[ -z "${S3_SECRET_KEY+x}" ]]; then
    >&2 echo "S3_SECRET_KEY must be set!"
    exit 1
fi
if [[ -z "${S3_HOST+x}" ]]; then
    >&2 echo "S3_HOST must be set!"
    exit 1
fi
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

