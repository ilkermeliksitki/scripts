import os

from utils import parse_video_id, get_choice, print_video_info, sanitize_title, get_video_title
from youtube_api import search_youtube

def handle_link(link, save, resolution):
    video_id = parse_video_id(link)
    title = sanitize_title(get_video_title(video_id))

    choice = get_choice('\na: audio only, v: video (enter for video): ', ['a', 'v'], default='v')

    if choice == 'a':
        if save:
            music_dir = os.path.expanduser('~/Music/youtube')
            audio_path = download_audio(video_id, title, music_dir)
            play_audio(audio_path, local=True)
        else:
            play_audio(link, local=False)
    elif choice == 'v':
        if save:
            video_dir = os.path.expanduser('~/Videos/youtube')
            video_path = download_video(video_id, title, resolution, video_dir)
            play_video(video_path, local=True)
        else:
            play_video(link, resolution=resolution, local=False)


def handle_query(query, save, resolution):
    videos = search_youtube(query)
    if not videos:
        print("No videos found.")
        return

    for video in videos:
        print_video_info(video)
        title = sanitize_title(video['title'])
        url = f"https://www.youtube.com/watch?v={video['video_id']}"

        choice = get_choice('\na: audio only, v: video, enter: next (enter to continue): ', ['a', 'v'], default='')

        if choice == 'a':
            music_dir = os.path.expanduser('~/Music/youtube')
            if save:
                audio_path = download_audio(video['video_id'], title, music_dir)
                play_audio(audio_path, local=True)
            else:
                play_audio(url, local=False)
        elif choice == 'v':
            video_dir = os.path.expanduser('~/Videos/youtube')
            if save:
                video_path = download_video(video['video_id'], title, resolution, video_dir)
                play_video(video_path, local=True)
            else:
                play_video(url, resolution=resolution, local=False)

