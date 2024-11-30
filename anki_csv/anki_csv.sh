#!/bin/bash

# CSV file name
CSV_FILE="/home/melik/Documents/projects/scripts/anki_csv/words.csv"

# add a word and definition to the CSV file
add_word_to_csv() {
    local word=$1
    local definition=$2

    # check if the file exists
    if [[ ! -f "$CSV_FILE" ]]; then
        # create the file and add the header
        echo "english_word,definition" > "$CSV_FILE"
    fi

    # append the word and definition to the CSV file by considering escaping the commas surrounded by double quotes
    echo "\"$word\",\"$definition\"" >> "$CSV_FILE"
}

# prompting for the word and definition
read -p "Enter the English word: " word
read -p "Enter the definition: " definition

# call the function
add_word_to_csv "$word" "$definition"

