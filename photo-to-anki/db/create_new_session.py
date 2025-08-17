import os
import subprocess
import sqlite3

def create_new_session(db_path, init_script):

    if not os.path.exists(db_path):
        subprocess.run(["bash", init_script])

    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    c.execute("INSERT INTO sessions DEFAULT VALUES")
    session_id = c.lastrowid
    
    conn.commit()
    conn.close()

    return session_id
