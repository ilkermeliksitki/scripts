import os
import sqlite3


def fetch_summary(session_id=None):
    """Return the running summary for the given session id (or env SESSION_ID).

    Returns an empty string if no summary is present.
    """
    db_path = os.getenv("DATABASE_PATH")
    if session_id is None:
        session_id = os.getenv("SESSION_ID")

    if not db_path or not session_id:
        return ""

    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute("SELECT summary FROM sessions WHERE id = ?", (session_id,))
    row = c.fetchone()
    conn.close()

    if not row or row[0] is None:
        return ""
    return row[0]


if __name__ == "__main__":
    import sys

    sid = None
    if len(sys.argv) > 1:
        sid = sys.argv[1]

    print(fetch_summary(sid))

