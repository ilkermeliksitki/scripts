#!/usr/bin/env python3

import sys
import re
import requests
import subprocess
from bs4 import BeautifulSoup
from datetime import datetime

def validate_args():
    if len(sys.argv) < 2:
        print("Usage: python3 tum_calendar_sync.py <html_file1> <html_file2> ...")
        sys.exit(1)


def read_html_file(html_file):
    with open(html_file, 'r') as file:
        return file.read()


def parse_appointments(html):
    soup = BeautifulSoup(html, 'html.parser')
    return soup.find_all('div', class_='appointment-compact slide-box')


def extract_course_title(html_file):
    return html_file.split('/')[-1].split('.')[0].replace('-', ' ').title()


def extract_date_time(apt_time):
    date_match = re.search(r'(\d{2}\.\d{2}\.\d{4}), (\d{2}:\d{2}) - (\d{2}:\d{2})', apt_time)
    if date_match:
        date = date_match.group(1)
        start_time = date_match.group(2)
        end_time = date_match.group(3)
        start_date = datetime.strptime(f"{date} {start_time}", '%d.%m.%Y %H:%M')
        end_date = datetime.strptime(f"{date} {end_time}", '%d.%m.%Y %H:%M')
        duration_min = (end_date - start_date).seconds / 60
        return start_date, duration_min
    return None, None


def extract_location(appointment):
    loc = appointment.find('div', class_='apt-location')
    if loc and loc.find('a') and loc.find('a').get('href') is not None:
        raum_key = re.search(r'raumKey=(\d+)', loc.find('a').get('href'))
        if raum_key:
            # use escape character for $ctx to avoid shell expansion
            return f"https://campus.tum.de/tumonline/ee/ui/ca2/app/desktop/#/pl/ui/\\$ctx/ris.einzelRaum?raumKey={raum_key.group(1)}"
    return "Location not specified"


def extract_note_text(appointment):
    note = appointment.find('div', class_='appointment-comment ng-star-inserted')
    return note.text.strip() if note else ""


def add_event_to_calendar(course_title, loc_href, start_date, duration_min, note_text):
    command = [
        'gcalcli', 'add',
        '--title', course_title,
        '--where', loc_href,
        '--when', str(start_date),
        '--duration', str(int(duration_min)),
        '--description', note_text
    ]
    subprocess.run(command)
    print(f"Added appointment on {start_date} to calendar.")


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
                exit()
    
    print("All appointments have been added to the calendar.")

if __name__ == "__main__":
    main()
