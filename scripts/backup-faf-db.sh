#!/usr/bin/env bash

BACKUP_DIR=/opt/faf/backups/faf-db

mkdir -p ${BACKUP_DIR}
docker exec -i faf-db mysqldump --login-path=faf_lobby --single-transaction --triggers --routines --all-databases | gzip -c > ${BACKUP_DIR}/$(date +"%Y-%m-%d-%H-%M-%S").sql.gzip
