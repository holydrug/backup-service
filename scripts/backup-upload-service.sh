#!/bin/bash

PERIOD="300" # 5 итерация по загрузке в 5 минут

while true; do
    BACKUP_DIR="/root/backups"
    LOG_FILE="/root/backups/log.txt"
    TOKEN='TOKEN'
    SERVERS_FOLDER="servers"
    MINECRAFT_FOLDER="$SERVERS_FOLDER/minecraft"
    YANDEX_FOLDER="$MINECRAFT_FOLDER"
    SPLIT_SIZE="2M"  # Размер частей (в данном случае, 2 мегабайта)

    # Функция для разбиения ZIP-архива на части
    function splitZip() {
        local file="$1"
        local folder_name="${file%.zip}"  # Имя архива без расширения
        local parent_folder="$BACKUP_DIR/parts/$folder_name"  # Путь к родительской папке для частей

        # Создаем каталог для частей архива
        mkdir -p "$parent_folder"

        local split_prefix="$parent_folder/${file%.zip}-part"  # Префикс для имен частей

        # Разбиваем архив на части
        echo "Splitting $file into parts..."
        split --numeric-suffixes --additional-suffix=.zip -b "$SPLIT_SIZE" "$file" "$split_prefix"
    }

    # Функция для отправки запроса на создание папки
    function createFolder() {
        local folder_path="$1"

        echo "Creating folder: $folder_path"
        curl -X PUT -H "Authorization: OAuth $TOKEN" "https://cloud-api.yandex.net/v1/disk/resources/?path=$folder_path" >/dev/null 2>&1
    }

    # Функция для отправки файла, если его еще не отправляли
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

        # Получаем URL для загрузки файла
        sendUrlResponse=$(curl -s -H "Authorization: OAuth $TOKEN" "https://cloud-api.yandex.net:443/v1/disk/resources/upload/?path=$parent_folder/$filename&overwrite=true")
        sendUrl=$(echo "$sendUrlResponse" | grep -o '"href":"[^"]*' | cut -d'"' -f4)

        # Отправляем файл в фоновом режиме
        echo "Uploading $filename to Yandex.Disk in the background..."
        curl -s -T "$file" -H "Authorization: OAuth $TOKEN" "$sendUrl" &>/dev/null &

        # Добавляем имя файла в журнал
        echo "$(date +"%Y-%m-%dT%H%M%S"): $filename" >> "$LOG_FILE"
    }

    # Переходим в папку с бекапами
    cd "$BACKUP_DIR" || exit

    # Создаем папки на Яндекс.Диске, если они еще не существуют
    createFolder "$SERVERS_FOLDER"
    createFolder "$MINECRAFT_FOLDER"

    # Создаем лог-файл, если он не существует
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi

    # Получаем список zip-файлов
    zip_files=( $(ls -t *.zip) )

    # Отправляем каждый архив
    for file in "${zip_files[@]}"; do
        folder_name="${file%.zip}"  # Имя архива без расширения

        # Создаем родительскую папку на Яндекс.Диске для каждого архива
        parent_folder="$YANDEX_FOLDER/$folder_name"
        createFolder "$parent_folder"

        splitZip "$file"  # Разбиваем архив на части
        parts=( $(ls "$BACKUP_DIR/parts/$folder_name"/*.zip) )  # Получаем список частей архива из созданного подкаталога
        for part in "${parts[@]}"; do
            sendFileAsync "$part" "$parent_folder"  # Отправляем каждую часть асинхронно
        done
    done

    echo "All files are being uploaded in the background."

    sleep "$PERIOD"
done
