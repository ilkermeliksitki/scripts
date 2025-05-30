#!/usr/bin/env python3

import os
import json
import argparse
import requests
import subprocess

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

contents = response_json['contents']['twoColumnSearchResultsRenderer']['primaryContents']['sectionListRenderer']['contents'][0]['itemSectionRenderer']['contents']

print('Press a to download the audio to mp3 format to ~/Music folder.')
print('Press v to download the video to ~/Videos/youtube folder.')

try:
    for content_dict in contents:
        if 'showingResultsForRenderer' in content_dict.keys():
            continue

        if 'videoRenderer' in content_dict.keys():
            video_id = content_dict.get('videoRenderer', {}).get('videoId', '')
            title = content_dict.get('videoRenderer', {}).get('title', {}).get('runs', [{}])[0].get('text', '')
            view_count = content_dict.get('videoRenderer', {}).get('viewCountText', {}).get('simpleText', '')
            length_text = content_dict.get('videoRenderer', {}).get('lengthText', {}).get('accessibility', {}).\
                    get('accessibilityData', {}).get('label', '')
            owner = content_dict.get('videoRenderer', {}).get('ownerText', {}).get('runs', [{}])[0].get('text', '')
            published_time = content_dict.get('videoRenderer', {}).get('publishedTimeText', {}).get('simpleText', '')

            print()
            print(title)
            print(video_id)
            print(view_count)
            print(length_text)
            print(owner)
            print(published_time)

            choice = input('Enter your choice (enter to continue): ').strip().lower()
            if choice == 'a':
                music_folder = os.path.expanduser('~/Music')
                if not os.path.exists(music_folder):
                    os.makedirs(music_folder)
                command = f'yt-dlp -x --audio-format mp3 -o "{music_folder}/%(title)s.%(ext)s" {video_id}'
                subprocess.run(command, shell=True)

                # play the downloaded audio with mpv
                subprocess.run(['mpv', f'{music_folder}/{title}.mp3'])
            elif choice == 'v':
                video_folder = os.path.expanduser('~/Videos/youtube')
                if not os.path.exists(video_folder):
                    os.makedirs(video_folder)
                command = (
                    f'yt-dlp -f "bestvideo[height<=720]+bestaudio" '
                    f'--merge-output-format mp4 '
                    f'-o "{video_folder}/%(title)s.%(ext)s" {video_id}'
                )

                subprocess.run(command, shell=True)

                # play the downloaded video with mpv
                subprocess.run(['mpv', f'{video_folder}/{title}.mp4'])
            else:
                continue
        print('\n')
except KeyboardInterrupt:
    print('\nExiting...')

