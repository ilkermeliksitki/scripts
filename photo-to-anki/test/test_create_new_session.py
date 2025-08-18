import os
import pytest
import sqlite3
import tempfile
from pathlib import Path
from unittest.mock import patch, MagicMock

from db.create_new_session import create_new_session


class TestCreateNewSession:
    
    def setup_method(self):
        self.temp_dir = tempfile.mkdtemp()
        self.db_path = Path(self.temp_dir) / "test_database.db"
        self.init_script = Path(self.temp_dir) / "init_test.sh"
        
        # Create a simple init script for testing
        with open(self.init_script, 'w') as f:
            f.write("""#!/bin/bash
                sqlite3 {} << EOF
                CREATE TABLE IF NOT EXISTS sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                EOF
            """.format(self.db_path))
        os.chmod(self.init_script, 0o755)

    def teardown_method(self):
        import shutil
        shutil.rmtree(self.temp_dir)

    def test_create_new_session_with_existing_database(self):
        # create database with sessions table
        conn = sqlite3.connect(self.db_path)
        conn.execute("""
            CREATE TABLE sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
        conn.close()

        session_id = create_new_session(self.db_path, self.init_script)
        
        assert isinstance(session_id, int)
        assert session_id > 0

        # verify session was created in database
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM sessions WHERE id = ?", (session_id,))
        count = cursor.fetchone()[0]
        conn.close()
        
        assert count == 1

    @patch('subprocess.run')
    def test_create_new_session_without_existing_database(self, mock_subprocess):
        # database doesn't exist initially
        assert not self.db_path.exists()
        
        # after init script runs, create the database
        def init_side_effect(*args, **kwargs):
            conn = sqlite3.connect(self.db_path)
            conn.execute("""
                CREATE TABLE sessions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )""")
            conn.commit()
            conn.close()
        
        # tl;dr whenever someone calls you, instead of just returning something, run this function.
        mock_subprocess.side_effect = init_side_effect

        session_id = create_new_session(self.db_path, self.init_script)

        # assert that the mock was called exactly once and that call was with the specified arguments.
        mock_subprocess.assert_called_once_with(["bash", self.init_script])

        assert isinstance(session_id, int)
        assert session_id > 0
        

    def test_create_multiple_sessions(self):
        # create database with sessions table
        conn = sqlite3.connect(self.db_path)
        conn.execute("""
            CREATE TABLE sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )""")
        conn.commit()
        conn.close()

        session_id1 = create_new_session(self.db_path, self.init_script)
        session_id2 = create_new_session(self.db_path, self.init_script)
        
        assert session_id1 != session_id2
        assert session_id2 > session_id1

        # verify both sessions exist in database
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM sessions")
        count = cursor.fetchone()[0]
        conn.close()
        
        assert count == 2
