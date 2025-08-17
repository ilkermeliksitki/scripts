import os
import base64
import sqlite3
import argparse

def _save_image_bytes(session_id, image_bytes, mime_type):
    if mime_type == "image/png":
        ext = "png"
    elif mime_type in ("image/jpeg", "image/jpg"):
        ext = "jpg"
    else:
        raise ValueError(f"Unsupported MIME type: {mime_type}")

    rand = os.urandom(6).hex()
    fname = f"img_{session_id}_{rand}.{ext}"
    full_path = os.path.join(os.getenv("IMAGES_DIR"), fname)
    with open(full_path, "wb") as f:
        f.write(image_bytes)

    return full_path


def save_message(session_id, sender, text_content=None, image_bytes=None, mime_type="image/png"):
    """save a message (text or image) to the local DB"""
    db_path = os.getenv("DATABASE_PATH")
    conn = sqlite3.connect(db_path)
    c = conn.cursor()

    image_id = None

    if image_bytes:
        image_path = _save_image_bytes(session_id, image_bytes, mime_type)
        c.execute(
            "INSERT INTO images (session_id, path, mime) VALUES (?, ?, ?)",
            (session_id, image_path, mime_type)
        )
        image_id = c.lastrowid

    # add the message to the messages table
    c.execute(
        "INSERT INTO messages (session_id, sender, content, image_id) VALUES (?, ?, ?, ?)",
        (session_id, sender, text_content, image_id)
    )
    conn.commit()
