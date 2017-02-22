set -euf -o pipefail

if [ -z "${S3_HOST_BUCKET+x}" ] && [ -n "${S3_HOST+x}" ]; then
    export S3_HOST_BUCKET="%(bucket)s.${S3_HOST}"
    echo "S3_HOST_BUCKET was not defined so has been set to '${S3_HOST_BUCKET}' based on the value of S3_HOST."
fi
