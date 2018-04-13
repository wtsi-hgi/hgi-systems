#!/usr/bin/env bash

set -eu -o pipefail

MC="/opt/postgres-s3-backup/mc"
MC_CONFIG="/etc/postgres-s3-backup/mc"
PYTHON="/opt/postgres-s3-backup/venv/bin/python"
BACKUP_INFO_SCRIPT="/opt/postgres-s3-backup/backup-info.py"
BACKUP_LOCATION="backup-server/ansible-postgres-s3-backup-9-5-test-instance/"
BACKUPS_TO_KEEP=14
BACKUP_SUFFIX=""

function getBackupInformation()
{
    echo "$("${PYTHON}" "${BACKUP_INFO_SCRIPT}" \
                    --backups ${BACKUPS_TO_KEEP}  \
                    --suffix "${BACKUP_SUFFIX}" \
                    --mc "${MC}" \
                    --mc-config "${MC_CONFIG}" \
                    --mc-s3-location "${BACKUP_LOCATION}" \
                )"
}

echo "$(getBackupInformation)"
exit


# Create new backup
backupName="$(getBackupInformation | jq -r '.new' )"
uploadLocation="${BACKUP_LOCATION}${backupName}"

>&2 echo "Uploading backup to: ${uploadLocation}"
sudo -u postgres pg_dumpall \
    | gzip \
    | "${MC}" -C "${MC_CONFIG}" pipe "${uploadLocation}"

# Delete old backups
backupsToDelete="$(getBackupInformation | jq -r '.delete[]' | tr '\n' ' ' )"
for backupToDelete in ${backupsToDelete}; do
    toDelete="${BACKUP_LOCATION}${backupToDelete}"
    "${MC}" -C "${MC_CONFIG}" rm "${toDelete}"
done
