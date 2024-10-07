#!/usr/bin/env python3

import os
import sys
import json
import argparse
import requests
import subprocess

# the location for downloading
os.chdir('/home/melik/Videos/youtube/')

# create a parser
parser = argparse.ArgumentParser(description='query youtube and get the relevant results.')
parser.add_argument('query', type=str, help='The query to search in youtube.')

# parse the arguments
args = parser.parse_args()

# Set the API endpoint and API key
endpoint = "https://www.youtube.com/youtubei/v1/search"

# Set the search query
query = args.query

# Set the request payload as a JSON object
payload = {
    "context": {
        "client": {
            "clientName": "WEB",
            "clientVersion": "2.20220506.00.00"
        }
    },
    "query": query,
}

# Send the POST request with the payload
response = requests.post(endpoint, json=payload)

# Parse the response JSON
response_json = json.loads(response.content.decode())
ls = response_json['contents']['twoColumnSearchResultsRenderer']['primaryContents']['sectionListRenderer']['contents']
for i in ls:
    ls2 = i['itemSectionRenderer']['contents']
    for j in ls2:
        try:
            video_renderer = j['videoRenderer']
            # video id
            video_id = video_renderer['videoId']
            print(video_id)
            # video name
            # video_name = video_renderer['title']['runs'][0]['text']
            # print(video_name)
            # video name with date
            video_name_with_date = video_renderer['title']['accessibility']['accessibilityData']['label']
            print(video_name_with_date)

            # video length
            print(video_renderer['lengthText']['simpleText'])
            print(video_renderer['viewCountText']['simpleText'])
            print(video_renderer['ownerText']['runs'][0]['text'])
            print('-' * 100)
            try:
                inp = input('Enter for the next one, l for listening: ')
            except KeyboardInterrupt:
                print()
                sys.exit(1)
            except EOFError:
                print()
                sys.exit(2)
            if inp == 'l':
                opt_name = input('Enter the output name of the music: ')
                if opt_name == "":
                    subprocess.run(f'yt-dlp -f bestaudio --extract-audio --audio-format mp3 --audio-quality 0 {video_id}', shell=True)
                else:
                    subprocess.run(f'yt-dlp -f 247+249 {video_id} -o {opt_name}.webm && mpv "{opt_name}.webm"', shell=True)
                sys.exit(0)
        except KeyError:
            pass
    break

