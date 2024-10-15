from bs4 import BeautifulSoup
import re

with open('german-a1-1.html', 'r') as file:
    html = file.read()

soup = BeautifulSoup(html, 'html.parser')
appointments = soup.find_all('div', class_='appointment-compact slide-box')
for appointment in appointments:
    time = appointment.find('div', class_='apt-time').text # date  MON, 04.11.2024, 11:30 - 14:00  at  Room 002, Seminarraum (2903.EG.002)
    date = re.search(r'\d{2}\.\d{2}\.\d{4}, \d{2}:\d{2}', time).group()
    loc = appointment.find('div', class_='apt-location')
    href = "https://campus.tum.de/tumonline/ee/ui/ca2/" + loc.find('a')['href']
    print(date)
    print(href)
