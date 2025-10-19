#!/bin/bash

cd /home/melik/Documents/projects/scripts/language_learning/longman_to_anki/ || { echo "Failed to change directory" >> longman_cron.log 2>&1; exit 1; }

python3 longman_to_anki.py >> longman_cron.log 2>&1

# log completion with timestamp
echo "Longman cron run at $(date)" >> /home/melik/.cron.log 2>&1
