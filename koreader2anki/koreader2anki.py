#!/usr/bin/python3

import sys
import json
import datetime

def epoch_to_date(epoch_time):
    date_time = datetime.datetime.utcfromtimestamp(epoch_time)
    date_string = date_time.strftime('%Y-%m-%d %H:%M:%S')
    return date_string

def process_json_file(file_path):
    try:
        with open(file_path, 'r') as file:
            data = json.load(file)
            return data
    except FileNotFoundError:
        print(f"File '{file_path}' not found.")
    except json.JSONDecodeError:
        print(f"Error decoding JSON in file '{file_path}'.")

if __name__ == "__main__":
    # Check if a file path is provided as a command-line argument
    if len(sys.argv) != 2:
        print("Usage: koreader2anki.py <json-file>")
        sys.exit(1)

    # Get the file path from command-line arguments
    json_file_path = sys.argv[1]

    # Process the JSON file
    data = process_json_file(json_file_path)
    entries = data.get('entries')
    for entry in entries:
        time = entry.get('time')
        chapter = entry.get('chapter')
        page = entry.get('page')
        text = entry.get('text')

        print("-" * 20)
        formatted_text = f"{epoch_to_date(time)}\n"
        formatted_text += f"chapter {chapter}"
        formatted_text += f" page: {page}\n"
        formatted_text += f"{text}\n\n"

        print(formatted_text, end='\n\n')
