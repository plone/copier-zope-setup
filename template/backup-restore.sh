#!/bin/bash
# Restore script for repozo and blobstorage backup


set -e

REPOZO_COMMAND="uv run repozo"

BACKUP_BASE="./backups"
RESTORE_VAR_DIR="./zeo_server/var"
ZODB_FILE="${RESTORE_VAR_DIR}/Data.fs"
TARGET_BLOBSTORAGE="${RESTORE_VAR_DIR}/blobstorage"
BACKUP_ZODB_BASE="${BACKUP_BASE}/filestorage"
BACKUP_BLOBSTORAGE_BASE="${BACKUP_BASE}/blobstorage"
LATEST_LINK="${BACKUP_BLOBSTORAGE_BASE}/latest"


# Function to prompt for confirmation
confirm_restore() {
    echo "================================================"
    echo "WARNING: This will replace existing data!"
    echo "================================================"
    echo "This will replace the filestorage (Data.fs)."
    echo "This will replace the blobstorage."
    echo "Zope should be stopped before!"
    echo ""
    read -p "Are you sure? (yes/No): " confirmation

    if [ "$confirmation" != "yes" ]; then
        echo "Restore cancelled."
        exit 0
    fi
}


# Function to restore Data.fs using repozo
restore_datafs() {
    local date_arg="$1"

    echo "Restoring Data.fs to ${ZODB_FILE}"

    # Create filestorage directory if it doesn't exist
    mkdir -p "${RESTORE_VAR_DIR}/filestorage"

    # Remove old Data.fs and related files
    rm -f "${ZODB_FILE}"
    rm -f "${ZODB_FILE}.index"
    rm -f "${ZODB_FILE}.tmp"
    rm -f "${ZODB_FILE}.lock"
    rm -f "${ZODB_FILE}.old"

    # Restore using repozo
    if [ -n "$date_arg" ]; then
        echo "Restoring to date: $date_arg"
        $REPOZO_COMMAND -R -r "$BACKUP_ZODB_BASE" -o "$ZODB_FILE" -D "$date_arg"
    else
        echo "Restoring latest backup..."
        $REPOZO_COMMAND -R -r "$BACKUP_ZODB_BASE" -o "$ZODB_FILE"
    fi

    if [ $? -eq 0 ]; then
        echo "Data.fs restored successfully."
    else
        echo "Error: Data.fs restore failed!"
        exit 1
    fi
}


# Function to restore blobstorage
restore_blobstorage() {
    local restore_from="$1"

    echo "Restoring blobstorage ${TARGET_BLOBSTORAGE}"

    # Determine which backup to restore from
    if [ -z "$restore_from" ]; then
        # Use the latest backup
        if [ -L "$LATEST_LINK" ]; then
            restore_from=$(readlink -f "$LATEST_LINK")
            echo "Using latest backup: $restore_from"
        else
            echo "Error: Latest backup link not found at $LATEST_LINK"
            exit 1
        fi
    fi

    # Check if backup source exists
    if [ ! -d "$restore_from" ]; then
        echo "Error: Backup directory $restore_from does not exist!"
        exit 1
    fi

    # Remove existing blobstorage
    if [ -d "$TARGET_BLOBSTORAGE" ]; then
        echo "Removing existing blobstorage..."
        rm -rf "$TARGET_BLOBSTORAGE"
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$TARGET_BLOBSTORAGE")"

    # Restore blobstorage using rsync
    rsync -av --delete "$restore_from/" "$TARGET_BLOBSTORAGE/"

    if [ $? -eq 0 ]; then
        echo "Blobstorage restored successfully."
    else
        echo "Error: Blobstorage restore failed!"
        exit 1
    fi
}


# Function to restore to a specific date
restore_to_date() {
    local target_date="$1"

    echo "Restoring backup from date: $target_date"

    # Find the first blobstorage backup after the specified date
    local blob_backup=$(find "$BACKUP_BLOBSTORAGE_BASE" -maxdepth 1 -type d -name "????-??-??_??-??-??" | sort | awk -v date="$target_date" '$0 >= date' | head -n 1)

    if [ -z "$blob_backup" ]; then
        echo "Error: No blobstorage backup found for date $target_date or later"
        exit 1
    fi

    echo "Using blobstorage backup: $blob_backup"

    # Restore Data.fs to the specified date
    restore_datafs "$target_date"

    # Restore blobstorage from the found backup
    restore_blobstorage "$blob_backup"
}


# Main script logic
main() {
    echo "Plone Backup Restore Script"
    echo "============================"
    echo ""

    # Parse command line arguments
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "Usage: $0 [date]"
        echo ""
        echo "Restores Plone Data.fs and blobstorage from backup."
        echo ""
        echo "Options:"
        echo "  [date]    Optional. Restore to specific date in format: YYYY-MM-DD[-HH[-MM[-SS]]]"
        echo "            Example: 2025-10-28 or 2025-10-28-14-30-00"
        echo ""
        echo "If no date is specified, restores the latest backup."
        exit 0
    fi

    # Check if Plone is running
    echo "Please ensure Plone/Zope is stopped before running restore!"
    echo ""

    # Prompt for confirmation
    confirm_restore

    echo ""
    echo "Starting restore process..."
    echo ""

    # Restore based on whether date argument was provided
    if [ -n "$1" ]; then
        restore_to_date "$1"
    else
        restore_datafs
        restore_blobstorage
    fi

    echo ""
    echo "================================================"
    echo "Restore completed successfully!"
    echo "================================================"
    echo ""
    echo "Next steps:"
    echo "1. Start your Plone/Zope instance"
    echo "2. Verify the restored data"
    echo "3. Run any necessary migration steps if upgrading"
}


# Run main function
main "$@"
