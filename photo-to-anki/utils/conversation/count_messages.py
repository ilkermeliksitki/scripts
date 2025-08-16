import os
import sqlite3


def count_messages(session_id, db_path=None):
    if db_path is None:
        db_path = os.getenv("DATABASE_PATH")

    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute(
        "SELECT COUNT(*) FROM messages WHERE session_id = ?",
        (session_id,)
    )
    row = c.fetchone()
    conn.close()
    return row[0] if row and row[0] is not None else 0


if __name__ == "__main__":
    import sys
    sid = sys.argv[1] if len(sys.argv) > 1 else None
    print(count_messages(sid))

