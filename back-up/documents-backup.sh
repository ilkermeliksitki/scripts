#!/bin/bash

MOUNT_DIR="/media/melik"
SOURCE_DIR="/home/melik/Documents/"
DESTINATION_DIR="$MOUNT_DIR/Documents-backup"
EXTERNAL_DISK_UUID="80fe0eb0-a405-496e-bfdc-4792008037d2"
LOG_FILE="/home/melik/Documents/projects/scripts/back-up/documents-backup.log"

# put a line for distinguishing different log entries
echo '+'$(printf %.0s- {1..15})'-' $(date) '-'$(printf %.0s- {1..15})'+' >> $LOG_FILE

if grep -q $MOUNT_DIR /proc/mounts; then
    echo "External drive is already mounted." >> $LOG_FILE
    drive_already_open=true
else
    # mount the external drive
    sudo mount --uuid $EXTERNAL_DISK_UUID $MOUNT_DIR
    if [ $? -ne 0 ]; then
        echo "Error: Failed to mount external drive." >> $LOG_FILE
        exit 1
    fi
    echo "External drive mounted successfully." >> $LOG_FILE
    drive_already_open=false
fi

# back up the files inside the ~/Documents/
# --delete option tells rsync to delete files in destination
#   file if it is deleted in the source file.
sudo rsync -av --delete              \
    --update                         \
    --exclude='.git'                 \
    --exclude='*.swp'                \
    --exclude='documents-backup.log' \
    $SOURCE_DIR $DESTINATION_DIR  >> $LOG_FILE

if [ $? -ne 0 ]; then
    echo "Error: rsync gave the following error code: $?"  >> $LOG_FILE
    exit 1
else
    echo "rsync is successfully completed." >> $LOG_FILE
fi

# for slowing things down a bit for umounting
sleep 2

# close the external drive if it is not already opened.
if [ $drive_already_open != true ]; then
    sudo umount $MOUNT_DIR
    if [ $? -ne 0 ]; then
        echo "Error: Failed to umount external drive." >> $LOG_FILE
        exit 1
    else
        echo "External drive umounted successfully." >> $LOG_FILE
    fi
else
    echo "External drive remained mounted." >> $LOG_FILE
fi
