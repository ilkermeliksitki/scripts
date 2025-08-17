import os
import sqlite3
import base64
from datetime import datetime

DATABASE_PATH = os.getenv("DATABASE_PATH")
IMAGES_DIR = os.getenv("IMAGES_DIR")

def _save_image_bytes(session_id, image_bytes, mime_type, timestamp):
    ext = "bin"
    if mime_type == "image/png":
        ext = "png"
    elif mime_type in ("image/jpeg", "image/jpg"):
        ext = "jpg"
    elif mime_type == "image/webp":
        ext = "webp"

    rand = os.urandom(6).hex()
    fname = f"img_{session_id}_{int(timestamp)}_{rand}.{ext}"
    full_path = os.path.join(IMAGES_DIR, fname)
    with open(full_path, "wb") as f:
        f.write(image_bytes)

    return full_path


def save_message(session_id, sender, content, message_type="text", image_description=None, image_prompt=None):
    conn = sqlite3.connect(DATABASE_PATH)
    c = conn.cursor()

    current_time = datetime.timestamp(datetime.now())

    image_path = None

    if message_type == "image":
        # expected format: data:<mime>;base64,<b64data>
        try:
            header, b64data = content.split(",", 1)
            mime = header.split(";")[0].replace("data:", "")
            image_bytes = base64.b64decode(b64data)
            image_path = _save_image_bytes(session_id, image_bytes, mime, current_time)
            if image_prompt:
                content = f"image prompt: {image_prompt}, image description: {image_description or 'No description provided'}"
            else:
                content = f"image description: {image_description or 'No description provided'}"
        except Exception as e:
            print(f"Error processing image content: {e}")
            sys.exit(1)
            image_path = None

    c.execute("""
    INSERT INTO messages (session_id, sender, content, type, timestamp, image_path, image_description)
    VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (session_id, sender, content, message_type, current_time, image_path, image_description))

    conn.commit()
    conn.close()

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 4:
        print("Usage: python save_message.py <session_id> <sender> <content> [<message_type>] [<image_description>]")
        sys.exit(1)

    session_id = sys.argv[1]
    sender = sys.argv[2]
    content = sys.argv[3]
    message_type = sys.argv[4] if len(sys.argv) > 4 else "text"
    image_description = sys.argv[5] if len(sys.argv) > 5 else None
    image_prompt = sys.argv[6] if len(sys.argv) > 6 else None

    save_message(session_id, sender, content, message_type, image_description, image_prompt)
