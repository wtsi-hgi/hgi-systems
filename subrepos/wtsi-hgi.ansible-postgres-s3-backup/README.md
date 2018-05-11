[![Build Status](https://travis-ci.org/wtsi-hgi/ansible-postgres-s3-backup.svg)](https://travis-ci.org/wtsi-hgi/ansible-postgres-s3-backup)

# Ansible Postgres S3 Backup
_An Ansible role to backup Postgres to S3_.

This role to sets up a cron job that streams a Postgres database dump in S3 using 
[minio](https://github.com/minio/minio). The backup script is able to rotate the backups such that only the last `n` are
kept.


## Requirements
### Runner
- ansible
- boto

### Host
It is assumed the host is a Debian based machine.


## Configuration
For a list of configuration options, [please see the defaults file](defaults/main.yml).


## Development
It is possible to test the role using `run-tests-in-docker.sh`. In order for this to work, `docker` and `docker-compose`
must be setup on your test machine.
