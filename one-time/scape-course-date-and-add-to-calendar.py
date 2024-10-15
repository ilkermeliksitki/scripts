import re
import requests
from bs4 import BeautifulSoup

with open('biostatistics.html', 'r') as file:
    html = file.read()

soup = BeautifulSoup(html, 'html.parser')
appointments = soup.find_all('div', class_='appointment-compact slide-box')
for appointment in appointments:
    # date
    apt_time = appointment.find('div', class_='apt-time').text # date  MON, 04.11.2024, 11:30 - 14:00  at  Room 002, Seminarraum (2903.EG.002)
    date = re.search(r'\d{2}\.\d{2}\.\d{4}, \d{2}:\d{2}', apt_time).group()

    # location
    loc = appointment.find('div', class_='apt-location')
    loc_href = None
    if loc.find('a').get('href') is not None:
        loc_href = "https://campus.tum.de/tumonline/ee/ui/ca2/" + loc.find('a').get('href')

    # note
    note = appointment.find('div', class_='appointment-comment ng-star-inserted')
    if note:
        pass
    else:
        note = None

