#!/usr/bin/env bash
# This scripts creates a rotating backup of the last 7 days.
# Subfolder 01 contains the newewst, subfolder 07 the latest backup.

# modify the following to suit your environment
export DB_BACKUP="/opt/faf/backups/faf-db"

echo "*** MySQL backup"
echo "* Rotate existing backups"
echo "------------------------"

rm -rf $DB_BACKUP/07
mv $DB_BACKUP/06 $DB_BACKUP/07
mv $DB_BACKUP/05 $DB_BACKUP/06
mv $DB_BACKUP/04 $DB_BACKUP/05
mv $DB_BACKUP/03 $DB_BACKUP/04
mv $DB_BACKUP/02 $DB_BACKUP/03
mv $DB_BACKUP/01 $DB_BACKUP/02
mkdir $DB_BACKUP/01

echo "* Creating backup..."
echo "------------------------"
docker exec -i -u root faf-db mysqldump --single-transaction --triggers --routines --all-databases | bzip2  > ${DB_BACKUP}/01/$(date +"%Y-%m-%d-%H-%M-%S").sql.bz2
echo "Done"
exit 0
