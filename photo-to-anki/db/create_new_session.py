import os
import subprocess
import sqlite3

DATABASE_PATH = os.getenv("SCRIPT_DIR") + "/db/database.db"
INIT_DATABASE_SCRIPT = os.getenv("SCRIPT_DIR") + "/db/init_database.sh"

def create_new_session():

    if not os.path.exists(DATABASE_PATH):
        subprocess.run(["bash", INIT_DATABASE_SCRIPT])

    conn = sqlite3.connect(DATABASE_PATH)
    c = conn.cursor()
    
    c.execute("INSERT INTO sessions (summary) VALUES (NULL)")
    session_id = c.lastrowid  # Get the auto-incremented session ID
    
    conn.commit()
    conn.close()

    return session_id

if __name__ == "__main__":
    print(create_new_session())

