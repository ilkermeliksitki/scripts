#!/bin/bash

# CSV directory
CSV_DIR="/home/melik/Documents/projects/scripts/anki_csv"

topic_to_parsed_filename() {
    local topic="$1"
    # lowercase, replace spaces with underscores, remove special characters
    echo "$topic" | tr '[:upper:]' '[:lower:]' | sed 's/ /_/g; s/[^a-z0-9_-]//g'
}

# create a function to add the anki item
add_anki_item() {
    local front=$1
    local back=$2
    local topic=$3

    local topic_filename
    topic_filename=$(topic_to_parsed_filename "$topic")
    local csv_file="$CSV_DIR/anki_items-$topic_filename.csv"

    # check if the file exists
    if [[ ! -f "$csv_file" ]]; then
        # create the file and add the header
        echo "front,back" > "$csv_file"
    fi

    echo "\"$front\",\"$back\"" >> "$csv_file"
}

if [[ $# -lt 2 ]]; then
    echo "Usage: anki_csv <front> <back> [topic]"
    exit 1
fi

front="$1"
if [[ -z "$front" ]]; then
    echo "Error: Front cannot be empty."
    exit 1
fi

back="$2"
topic="${3:-english}"

add_anki_item "$front" "$back" "$topic"

echo -e "Front: $front\nBack: $back\nTopic: $topic\nare added to the CSV file." 2>&1
