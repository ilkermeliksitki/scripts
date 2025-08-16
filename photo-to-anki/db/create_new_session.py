import os
import subprocess
import sqlite3

def create_new_session(db_path, init_script):

    if not os.path.exists(db_path):
        subprocess.run(["bash", init_script])

    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    c.execute("INSERT INTO sessions (summary) VALUES (NULL)")
    session_id = c.lastrowid  # Get the auto-incremented session ID
    
    conn.commit()
    conn.close()

    return session_id

if __name__ == "__main__":
    print(create_new_session())

