import os
import sqlite3
import base64
import sys
from datetime import datetime
import argparse

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

    image_id = None
    if message_type == "image":
        # expected format: data:<mime>;base64,<b64data>
        try:
            header, b64data = content.split(",", 1)
            mime = header.split(";")[0].replace("data:", "")
            image_bytes = base64.b64decode(b64data)
            image_path = _save_image_bytes(session_id, image_bytes, mime, current_time)
            try:
                c.execute("""
                INSERT INTO images (session_id, path, description, prompt, mime, timestamp)
                VALUES (?, ?, ?, ?, ?, ?)
                """, (session_id, image_path, image_description, image_prompt, mime, current_time))
                image_id = c.lastrowid
            except Exception:
                # if images table doesn't exist or insert fails, fall back to no image_id
                image_id = None

            if image_prompt:
                content = image_prompt
            else:
                content = "no prompt provided for the image by the user"
        except Exception as e:
            print(f"Error processing image content: {e}")
            content = None
            image_id = None

    c.execute("""
    INSERT INTO messages (session_id, sender, content, type, timestamp, image_id)
    VALUES (?, ?, ?, ?, ?, ?)
    """, (session_id, sender, content, message_type, current_time, image_id))

    conn.commit()
    conn.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Save a message to the local DB")
    parser.add_argument("--session-id",        dest="session_id",        required=True)
    parser.add_argument("--sender",            dest="sender",            required=True)
    parser.add_argument("--content",           dest="content",           required=True)
    parser.add_argument("--message-type",      dest="message_type",      default="text")
    parser.add_argument("--image-description", dest="image_description", default=None)
    parser.add_argument("--image-prompt",      dest="image_prompt",      default=None)

    args = parser.parse_args()
    session_id = args.session_id
    sender = args.sender
    content = args.content
    message_type = args.message_type
    image_description = args.image_description
    image_prompt = args.image_prompt

    # normalize empty strings to None
    if image_description == "":
        image_description = None
    if image_prompt == "":
        image_prompt = None

    save_message(session_id, sender, content, message_type, image_description, image_prompt)
