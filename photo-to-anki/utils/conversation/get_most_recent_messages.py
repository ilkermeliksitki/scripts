import os
import base64
import sqlite3

def get_most_recent_messages(session_id, limit=5, db_path=None):
    """
    fetch the most recent messages for a given session_id from the database
    in a manually managed conversation state way.
    https://platform.openai.com/docs/guides/conversation-state?api-mode=responses#manually-manage-conversation-state

    the texts and the images will be fetched sequentially and returned in the form of list of dicts as follows:
    [
      {
        "role": "user",
        "content": [
          {"type": "input_text", "text": "What’s in this image?"},                    <= prompt about the image
          {"type": "input_image", "image_url": "https://example.com/image.png"},      <= related image
        ],
      },
      {"role": "assistant", "content": "An example image."},
      {"role": "user", "content": "What does this image show?"},
      etc.
    ]
    """
    if db_path is None:
        db_path = os.getenv("DATABASE_PATH")

    conn = sqlite3.connect(db_path)
    c = conn.cursor()

    c.execute("""
        SELECT m.sender, m.content, i.path, i.mime
        FROM messages m
        LEFT JOIN images i ON m.image_id = i.id
        WHERE m.session_id = ?
        ORDER BY m.timestamp DESC
        LIMIT ?
    """, (session_id, limit))
    rows = c.fetchall()
    conn.close()

    api_input = []
    # reverse for chronological order
    rows.reverse()
    for sender, content, image_path, image_mime in rows:
        if sender == "minerva":
            sender = "assistant"
        entry = {"role": sender, "content": []}

        # handle text
        if content:
            if sender == "assistant":
                # a simple string for assistant messages (assuming it provides text only currently)
                entry["content"] = content
            else:
                entry["content"].append({"type": "input_text", "text": content})

        # handle image
        if image_path and os.path.exists(image_path):
            with open(image_path, "rb") as f:
                image_bytes = f.read()
                image_b64 = base64.b64encode(image_bytes).decode('utf-8')
            data_url = f"data:{image_mime};base64,{image_b64}"
            entry["content"].append({"type": "input_image", "image_url": data_url})

        api_input.append(entry)

    # print for debugging
    for i in api_input:
        print(i)

    return api_input
