## Script for backing up files (or creating a backup of your virtual machine) to Yandex.Disk
### Example backup of a Minecraft server

[backup-upload-service.sh](scripts%2Fbackup-upload-service.sh)

This script archives the specified directory into the designated folder.

For example:

/root/minecraft-modded 

Will be archived into an archive named archive_2024-02-22T143025.zip
It will save this backup in

/root/backups

------------

[backup-zipping-service.sh](scripts%2Fbackup-zipping-service.sh)

Fill in the variables in the script:

1. BACKUP_DIR: Path to the directory where backups are stored.
2. LOG_FILE: Path to the log file where backup information is recorded.
3. TOKEN: Authentication token for accessing Yandex.Disk.

Получить токен можно тут [Yandex Rest API](https://yandex.ru/dev/disk/rest/)

4. SERVERS_FOLDER: Folder containing server backups.
5. DOMAIN_FOLDER: Path to the domain backup folder.
6. YANDEX_FOLDER: Path to the folder on Yandex.Disk where backups will be stored (ENTIRE PATH).
7. SPLIT_SIZE: Size of parts into which the ZIP archive will be split before sending to Yandex.Disk.

### Note: Due to the limited upload speed of 128 kilobits per second on Yandex.Disk, it is necessary to split the files into smaller parts for efficient uploading.
[Quotas and limits in API Gateway](https://cloud.yandex.com/en/docs/api-gateway/concepts/limits)
