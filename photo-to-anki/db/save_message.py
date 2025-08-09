import sys
import sqlite3
from datetime import datetime

def save_message(session_id, sender, content, message_type="text"):
    conn = sqlite3.connect("database.db")
    c = conn.cursor()

    c.execute("""
    INSERT INTO messages (session_id, sender, content, type, timestamp)
    VALUES (?, ?, ?, ?, ?)
    """, (session_id, sender, content, message_type, datetime.now()))

    conn.commit()
    conn.close()

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python save_message.py <session_id> <sender> <content> [<message_type>]")
        sys.exit(1)

    session_id = sys.argv[1]
    sender = sys.argv[2]
    content = sys.argv[3]
    message_type = sys.argv[4]

    save_message(session_id, sender, content, message_type)

