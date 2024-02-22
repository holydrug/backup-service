#!/bin/bash

DIRECTORY_TO_ZIP="/root/minecraft-modded"
backup_directory="/root/backups/"
PERIOD=300 # period in seconds
DELETE_FILES_OLDER_THAN_HOURS=24 # number of hours after which to delete files

create_zip_with_timestamp() {
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H%M%S")
    ZIP_FILENAME="${backup_directory}/archive_${TIMESTAMP}.zip"
    zip -r "${ZIP_FILENAME}" "${DIRECTORY_TO_ZIP}"
}

delete_old_files() {
    find "${DIRECTORY_TO_ZIP}" -type f -mmin +$((DELETE_FILES_OLDER_THAN_HOURS * 60)) -exec rm {} \;
}

# Check if the directory to be zipped exists
if [ ! -d "${DIRECTORY_TO_ZIP}" ]; then
    echo "Error: Directory to be zipped '${DIRECTORY_TO_ZIP}' does not exist."
    exit 1
fi

# Check if the backup directory exists and create it if necessary
if [ ! -d "${backup_directory}" ]; then
    mkdir -p "${backup_directory}"
fi

while true; do
    create_zip_with_timestamp
    delete_old_files
    sleep ${PERIOD}
done
