#!/bin/bash

cd /home/melik/Documents/projects/scripts/language_learning/merriam_webster_to_anki/ || {
    echo "Failed to change directory." >> merriam_webster_cron.log 2>&1; exit 1;
}

python3 merriam_webster_to_anki.py >> merriam_webster_cron.log 2>&1

echo "Merriam-Webster cron run at $(date)" >> ${HOME}/.cron.log 2>&1
