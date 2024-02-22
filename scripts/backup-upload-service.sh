#!/bin/bash

PERIOD="300" # 5 iterations for 5-minute intervals

while true; do
    BACKUP_DIR="/root/backups"
    LOG_FILE="/root/backups/log.txt"
    TOKEN='TOKEN'
    SERVERS_FOLDER="servers"
    DOMAIN_FOLDER="$SERVERS_FOLDER/minecraft"
    YANDEX_FOLDER="$DOMAIN_FOLDER"
    SPLIT_SIZE="2M"  # Size of parts (in this case, 2 megabytes)

    # Function to split a ZIP archive into parts
    function splitZip() {
        local file="$1"
        local folder_name="${file%.zip}"  # Archive name without extension
        local parent_folder="$BACKUP_DIR/parts/$folder_name"  # Path to parent folder for parts

        # Create directory for archive parts
        mkdir -p "$parent_folder"

        local split_prefix="$parent_folder/${file%.zip}-part"  # Prefix for part names

        # Split the archive into parts
        echo "Splitting $file into parts..."
        split --numeric-suffixes --additional-suffix=.zip -b "$SPLIT_SIZE" "$file" "$split_prefix"
    }

    # Function to send a request to create a folder
    function createFolder() {
        local folder_path="$1"

        echo "Creating folder: $folder_path"
        curl -X PUT -H "Authorization: OAuth $TOKEN" "https://cloud-api.yandex.net/v1/disk/resources/?path=$folder_path" >/dev/null 2>&1
    }

    # Function to send a file if it has not been sent yet
    function sendFileAsync() {
        local file="$1"
        local filename=$(basename "$file")
        local parent_folder="$2"
        local parent_folder_name=$(basename "$parent_folder")

        if [[ $filename != *part* ]]; then
            echo "Skipping parent ZIP file: $filename"
            echo "$(date +"%Y-%m-%dT%H%M%S"): $filename - Skipped" >> "$LOG_FILE"
            return
        fi

        if grep -q "$filename" "$LOG_FILE"; then
            echo "File $filename has already been sent. Skipping."
            return
        fi

        echo "Sending file: $filename"

        # Get URL for file upload
        sendUrlResponse=$(curl -s -H "Authorization: OAuth $TOKEN" "https://cloud-api.yandex.net:443/v1/disk/resources/upload/?path=$parent_folder/$filename&overwrite=true")
        sendUrl=$(echo "$sendUrlResponse" | grep -o '"href":"[^"]*' | cut -d'"' -f4)

        # Upload the file in the background
        echo "Uploading $filename to Yandex.Disk in the background..."
        curl -s -T "$file" -H "Authorization: OAuth $TOKEN" "$sendUrl" &>/dev/null &

        # Add filename to the log
        echo "$(date +"%Y-%m-%dT%H%M%S"): $filename" >> "$LOG_FILE"
    }

    # Navigate to the backup directory
    cd "$BACKUP_DIR" || exit

    # Create folders on Yandex.Disk if they do not exist yet
    createFolder "$SERVERS_FOLDER"
    createFolder "$DOMAIN_FOLDER"

    # Create the log file if it does not exist
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi

    # Get a list of zip files
    zip_files=( $(ls -t *.zip) )

    # Send each archive
    for file in "${zip_files[@]}"; do
        folder_name="${file%.zip}"  # Archive name without extension

        # Create a parent folder on Yandex.Disk for each archive
        parent_folder="$YANDEX_FOLDER/$folder_name"
        createFolder "$parent_folder"

        splitZip "$file"  # Split the archive into parts
        parts=( $(ls "$BACKUP_DIR/parts/$folder_name"/*.zip) )  # Get a list of archive parts from the created subdirectory
        for part in "${parts[@]}"; do
            sendFileAsync "$part" "$parent_folder"  # Send each part asynchronously
        done
    done

    echo "All files are being uploaded in the background."

    sleep "$PERIOD"
done
