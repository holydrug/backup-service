#!/bin/bash

DIRECTORY_TO_ZIP="/root/minecraft-modded"
backup_directory="/root/backups/"
PERIOD=300 # период в секундах
DELETE_FILES_OLDER_THAN_HOURS=24 # количество часов, после которых удалять файлы

create_zip_with_timestamp() {
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H%M%S")
    ZIP_FILENAME="${backup_directory}/archive_${TIMESTAMP}.zip"
    zip -r "${ZIP_FILENAME}" "${DIRECTORY_TO_ZIP}"
}

delete_old_files() {
    find "${DIRECTORY_TO_ZIP}" -type f -mmin +$((DELETE_FILES_OLDER_THAN_HOURS * 60)) -exec rm {} \;
}

# Проверяем наличие каталога с файлами для архивации
if [ ! -d "${DIRECTORY_TO_ZIP}" ]; then
    echo "Ошибка: Каталог с файлами для архивации '${DIRECTORY_TO_ZIP}' не существует."
    exit 1
fi

# Проверяем наличие каталога для резервных копий и создаем его при необходимости
if [ ! -d "${backup_directory}" ]; then
    mkdir -p "${backup_directory}"
fi

while true; do
    create_zip_with_timestamp
    delete_old_files
    sleep ${PERIOD}
done
