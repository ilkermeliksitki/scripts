import os
import sqlite3


def get_user_message_count(session_id=None):
    db_path = os.getenv("DATABASE_PATH")
    if session_id is None:
        session_id = os.getenv("SESSION_ID")

    if not db_path or not session_id:
        return 0

    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute("SELECT COUNT(*) FROM messages WHERE session_id = ? AND sender = 'user'", (session_id,))
    row = c.fetchone()
    conn.close()

    return row[0] if row else 0


if __name__ == "__main__":
    import sys
    sid = None
    if len(sys.argv) > 1:
        sid = sys.argv[1]
    print(get_user_message_count(sid))

