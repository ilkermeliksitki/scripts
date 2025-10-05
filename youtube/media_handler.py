import os
import subprocess

from utils import sanitize_title, get_video_title, normalize_audio

def download_audio(video_id, title, save_dir):
    if not os.path.exists(save_dir):
        os.makedirs(save_dir)

    if title is None:
        title = sanitize_title(get_video_title(video_id))

    path = os.path.join(save_dir, f"{title}.mp3")
    command = [
        "yt-dlp",
        "-f", "bestaudio",
        "--output", path,
        f"https://www.youtube.com/watch?v={video_id}",
    ]
    subprocess.run(command)

    normalize_audio(path)

    return path


def download_video(video_id, title, resolution, save_dir):
    if not os.path.exists(save_dir):
        os.makedirs(save_dir)

    if title is None:
        title = sanitize_title(get_video_title(video_id))

    path = os.path.join(save_dir, f"{title}.mp4")
    command = [
        "yt-dlp",
        "-f", f"bestvideo[height<={resolution}]+bestaudio",
        "--merge-output-format", "mp4",
        "--output", path,
        f"https://www.youtube.com/watch?v={video_id}",
    ]
    subprocess.run(command)
    return path


def play_audio(path_or_url, local=True):
    if local:
        command = ["mpv", path_or_url]
    else:
        command = ["mpv", "--ytdl-format=bestaudio", path_or_url]
    subprocess.run(command)


def play_video(path_or_url, resolution=None, local=True):
    if local:
        command = ["mpv", path_or_url]
    else:
        ytdl_format = f"bestvideo[height<={resolution}]+bestaudio" if resolution else "best"
        command = ["mpv", f"--ytdl-format={ytdl_format}", path_or_url]
    subprocess.run(command)

