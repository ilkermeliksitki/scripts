#!/usr/bin/env python3

import os
import argparse

from media_handler import download_audio, download_video, play_audio, play_video
from youtube_api import search_youtube
from utils import sanitize_title, print_video_info


def main():
    parser = argparse.ArgumentParser(description='query youtube and get the relevant results.')
    parser.add_argument('query', type=str, help='the query to search in YouTube.')
    parser.add_argument('-s', '--save', action='store_true', help='save the content')
    parser.add_argument('-r', '--resolution', type=int, default=540, help='the video resolution (default: 540)')
    args = parser.parse_args()

    videos = search_youtube(args.query)
    if not videos:
        print("No videos found.")
        return

    for video in videos:
        print_video_info(video)
        title = sanitize_title(video['title'])
        print('\na: audio only, v: video, enter: next')
        choice = input('Enter your choice (enter to continue): ').strip().lower()
        url = f"https://www.youtube.com/watch?v={video['video_id']}"

        if choice == 'a':
            music_dir = os.path.expanduser('~/Music/youtube')
            if args.save:
                audio_path = download_audio(video['video_id'], title, music_dir)
                play_audio(audio_path, local=True)
            else:
                play_audio(url, local=False)
        elif choice == 'v':
            resolution = args.resolution
            video_dir = os.path.expanduser('~/Videos/youtube')
            if args.save:
                video_path = download_video(video['video_id'], title, resolution, video_dir)
                play_video(video_path, local=True)
            else:
                play_video(url, resolution=resolution, local=False)
        else:
            continue

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\nExiting...")
        exit(0)
