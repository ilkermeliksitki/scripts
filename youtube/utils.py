import re
import os
import subprocess

def sanitize_title(title):
    title = title.strip()
    title = title.lower()
    # replace spaces with underscores
    title = re.sub(r'\s+', '_', title)
    # remove special characters e.g. !, ?, ., /
    title = re.sub(r'[^\w\-]', '', title)
    # _-_ => -
    title = re.sub(r'_+-+_', '-', title)
    return title


def print_video_info(video):
    print("\nTitle:", video['title'])
    print("Video ID:", video['video_id'])
    print("Views:", video['view_count'])
    print("Length:", video['length_text'])
    print("Owner:", video['owner'])
    print("Published:", video['published_time'])


def get_video_title(video_id):
    command = [
        "yt-dlp",
        "--get-title",
        f"https://www.youtube.com/watch?v={video_id}",
    ]
    title = subprocess.check_output(command).decode().strip()
    return title


def parse_video_id(link):
    if 'v=' in link:
        return link.split('v=')[-1].split('&')[0]
    elif 'youtu.be/' in link:
        return link.split('youtu.be/')[-1].split('?')[0]
    else:
        raise ValueError("Invalid YouTube link format.")


def get_choice(prompt, choices, default=None):
    choice = input(prompt).strip().lower()
    if choice in choices:
        return choice
    return default


def normalize_audio(path):
    temp_path = f"{path}.tmp.mp3"
    command = [
        "ffmpeg",
        "-i", path,
        "-af", "loudnorm=I=-16:TP=-1.5:LRA=11",
        "-y",  # Overwrite output file if it exists
        temp_path
    ]
    subprocess.run(command)
    os.replace(temp_path, path)
    print(f"Normalized audio saved to {path}")
