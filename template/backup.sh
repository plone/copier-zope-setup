#!/bin/bash
# repozo and blobstorage backup using rsync with hardlinks


set -e

# BACKUP_VAR_DIR = "./instance/var"
BACKUP_VAR_DIR="./zeo_server/var"

REPOZO_COMMAND="uv run repozo"
SOURCE_BLOBSTORAGE="${BACKUP_VAR_DIR}/blobstorage"
BACKUP_BLOBSTORAGE_BASE="./backups/blobstorage"
BACKUP_ZODB_BASE="./backups/filestorage"
ZODB_FILE="${BACKUP_VAR_DIR}/Data.fs"
CURRENT_BACKUP="$(date +%Y-%m-%d_%H-%M-%S)"
LATEST_LINK="${BACKUP_BLOBSTORAGE_BASE}/latest"

# Create backup directory
mkdir -p "${BACKUP_BLOBSTORAGE_BASE}/$CURRENT_BACKUP"
mkdir -p "${BACKUP_ZODB_BASE}"

# backup ZODB
$REPOZO_COMMAND -Bvz -r ${BACKUP_ZODB_BASE} -f ${ZODB_FILE}

# Perform blobstorage incremental backup with hardlinks
if [ -d "${BACKUP_BLOBSTORAGE_BASE}/$LATEST_LINK" ]; then
    rsync -av --delete --link-dest="${BACKUP_BLOBSTORAGE_BASE}/$LATEST_LINK" "$SOURCE_BLOBSTORAGE/" "${BACKUP_BLOBSTORAGE_BASE}/$CURRENT_BACKUP/"
else
    rsync -av "$SOURCE_BLOBSTORAGE/" "${BACKUP_BLOBSTORAGE_BASE}/$CURRENT_BACKUP/"
fi

# Update latest symlink
pwd
rm -f "$LATEST_LINK"
ln -s "$CURRENT_BACKUP" "$LATEST_LINK"
