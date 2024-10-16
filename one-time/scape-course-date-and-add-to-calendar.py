#!/usr/bin/env python3

import os
import sys
import re
import requests
from bs4 import BeautifulSoup
from datetime import datetime

# Check if file names are provided as arguments
if len(sys.argv) < 2:
    print("Usage: python scape-course-date-and-add-to-calendar.py <html_file1> <html_file2> ...")
    sys.exit(1)

# Process each HTML file
for html_file in sys.argv[1:]:
    with open(html_file, 'r') as file:
        html = file.read()

    soup = BeautifulSoup(html, 'html.parser')
    appointments = soup.find_all('div', class_='appointment-compact slide-box')
    course_title = html_file.split('.')[0].replace('-', ' ').title()
    for appointment in appointments:
        # date
        apt_time = appointment.find('div', class_='apt-time').text # date  MON, 04.11.2024, 11:30 - 14:00  at  Room 002, Seminarraum (2903.EG.002)
        date_match = re.search(r'(\d{2}\.\d{2}\.\d{4}), (\d{2}:\d{2}) - (\d{2}:\d{2})', apt_time)
        if date_match:
            date = date_match.group(1)
            start_time = date_match.group(2)
            end_time = date_match.group(3)
            start_date = datetime.strptime(f"{date} {start_time}", '%d.%m.%Y %H:%M')
            end_date = datetime.strptime(f"{date} {end_time}", '%d.%m.%Y %H:%M')
            duration_min = (end_date - start_date).seconds / 60
            print(start_date)

        # location
        loc = appointment.find('div', class_='apt-location')
        loc_href = None
        if loc and loc.find('a') and loc.find('a').get('href') is not None:
            raum_key = re.search(r'raumKey=(\d+)', loc.find('a').get('href'))
            # use escape character to escape the $ctx (disappears in shell commandi otherwise)
            loc_href = f"https://campus.tum.de/tumonline/ee/ui/ca2/app/desktop/#/pl/ui/\\$ctx/ris.einzelRaum?raumKey={raum_key.group(1)}"
            print(loc_href)
        else:
            loc_href = "Location not specified"

        # note
        note = appointment.find('div', class_='appointment-comment ng-star-inserted')
        if note:
            note_text = note.text.strip()
            print(note_text)
        else:
            note_text = ""

        # Use gcalcli to add the event to the calendar
        command = (
            f'gcalcli add --title "{course_title}" \
                    --where "{loc_href}" \
                    --when "{start_date}" \
                    --duration "{int(duration_min)}" \
                    --description "{note_text}"'
        )
        os.system(command)
        print(f"Added appointment on {start_date} to calendar.")
        exit()

print("All appointments have been added to the calendar.")

