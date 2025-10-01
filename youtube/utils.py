import re

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
