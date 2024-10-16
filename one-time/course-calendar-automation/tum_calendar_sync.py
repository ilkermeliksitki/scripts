#!/usr/bin/env python3

import re
import sys
import time
import logging
import requests
import subprocess
from bs4 import BeautifulSoup
from datetime import datetime

# configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("tum_calendar_sync.log"),
        logging.StreamHandler()
    ]
)

def validate_args():
    if len(sys.argv) < 2:
        logging.error("Usage: python3 tum_calendar_sync.py <html_file1> <html_file2> ...")
        sys.exit(1)
    logging.info("Arguments are validated successfully.")


def read_html_file(html_file):
    with open(html_file, 'r') as file:
        logging.info(f"Reading file: {html_file}")
        return file.read()


def parse_appointments(html):
    soup = BeautifulSoup(html, 'html.parser')
    appointments = soup.find_all('div', class_='appointment-compact slide-box')
    logging.info(f"Parsed {len(appointments)} appointments.")
    return appointments


def extract_course_title(html_file):
    course_title = html_file.split('/')[-1].split('.')[0].replace('-', ' ').title()
    logging.info(f"Extracted course title: {course_title}")
    return course_title


def extract_date_time(apt_time):
    date_match = re.search(r'(\d{2}\.\d{2}\.\d{4}), (\d{2}:\d{2}) - (\d{2}:\d{2})', apt_time)
    if date_match:
        date = date_match.group(1)
        start_time = date_match.group(2)
        end_time = date_match.group(3)
        start_date = datetime.strptime(f"{date} {start_time}", '%d.%m.%Y %H:%M')
        end_date = datetime.strptime(f"{date} {end_time}", '%d.%m.%Y %H:%M')
        duration_min = (end_date - start_date).seconds / 60
        logging.info(f"Extracted date and time: {start_date} for {duration_min} minutes.")
        return start_date, duration_min
    logging.warning("Failed to extract date and time.")
    return None, None


def extract_location(appointment):
    loc = appointment.find('div', class_='apt-location')
    if loc and loc.find('a') and loc.find('a').get('href') is not None:
        raum_key = re.search(r'raumKey=(\d+)', loc.find('a').get('href'))
        if raum_key:
            # use escape character for $ctx to avoid shell expansion
            loc_href = f"https://campus.tum.de/tumonline/ee/ui/ca2/app/desktop/#/pl/ui/\\$ctx/ris.einzelRaum?raumKey={raum_key.group(1)}"
            logging.info(f"Extracted location raum key: {raum_key.group(1)}")
            return loc_href
    logging.warning("Location not specified.")
    return "Location not specified"


def extract_note_text(appointment):
    note = appointment.find('div', class_='appointment-comment ng-star-inserted')
    note_text =  note.text.strip() if note else ""
    logging.info(f"Extracted note text: {note_text}")
    return note_text


def add_event_to_calendar(course_title, loc_href, start_date, duration_min, note_text):
    command = [
        'gcalcli', 'add',
        '--title', course_title,
        '--where', loc_href,
        '--when', str(start_date),
        '--duration', str(int(duration_min)),
        '--description', note_text,
        '--reminder', '1h',
        '--reminder', '10m'
    ]
    logging.info(f"Adding event to calendar with command: {' '.join(command)}")
    subprocess.run(command)
    logging.info(f"Added appointment on {start_date} to calendar.")


def main():
    validate_args()
    
    for html_file in sys.argv[1:]:
        html = read_html_file(html_file)
        appointments = parse_appointments(html)
        course_title = extract_course_title(html_file)
        
        for appointment in appointments:
            apt_time = appointment.find('div', class_='apt-time').text
            start_date, duration_min = extract_date_time(apt_time)
            if start_date:
                loc_href = extract_location(appointment)
                note_text = extract_note_text(appointment)
                add_event_to_calendar(course_title, loc_href, start_date, duration_min, note_text)
                time.sleep(1)
    
    logging.info("All appointments have been added to the calendar.")

if __name__ == "__main__":
    main()
