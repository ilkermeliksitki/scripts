import os
import sqlite3

def get_most_recent_messages(session_id, limit=3):
    db_path = os.getenv("DATABASE_PATH")

    conn = sqlite3.connect(db_path)
    c = conn.cursor()

    c.execute("""
    SELECT sender, content, type, timestamp
    FROM messages
    WHERE session_id = ?
    ORDER BY timestamp DESC
    LIMIT ?
    """, (session_id, limit))

    messages = c.fetchall()
    conn.close()
    return messages

