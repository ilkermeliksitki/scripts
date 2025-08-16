import os
import sqlite3

def get_most_recent_messages(session_id, limit=3, db_path=None):
    if db_path is None:
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

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 4:
        print("Usage: python fetch_recent_messages.py <session_id> <limit> [<db_path>]")
        sys.exit(1)
    session_id = sys.argv[1]
    limit = int(sys.argv[2])
    db_path = sys.argv[3] if len(sys.argv) > 3 else None
    messages = get_most_recent_messages(session_id, limit, db_path)
    for msg in messages:
        print(msg)
        print()
