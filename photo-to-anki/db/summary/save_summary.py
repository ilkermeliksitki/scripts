import os
import sys
import sqlite3

def save_summary(summary: str):
    db_path = os.getenv("DATABASE_PATH")
    session_id = os.getenv("SESSION_ID")
    conn = sqlite3.connect(db_path)
    curr = conn.cursor()

    try:
        curr.execute("UPDATE sessions SET summary = ? WHERE id = ?", (summary, session_id))
        conn.commit()
    except sqlite3.Error as e:
        print(f"An error occurred while saving the summary: {e}")
    finally:
        curr.close()
        conn.close()
