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

export MINIO_ENDPOINT="${S3_HOST}"
export MINIO_ACCESS_KEY_ID="${S3_ACCESS_KEY}"
export MINIO_SECRET_ACCESS_KEY="${S3_SECRET_KEY}"
