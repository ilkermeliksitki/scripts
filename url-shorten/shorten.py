#!/usr/bin/env python3

import sys, sqlite3, string, random, os

DB_FILE = "urls.db"

def init_db():
    conn = sqlite3.connect(DB_FILE)
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS urls (
            code TEXT PRIMARY KEY,
            url TEXT NOT NULL
        )
    """)
    conn.commit()
    return conn

def generate_code(length=6):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def add_url(url):
    conn = init_db()
    cur = conn.cursor()

    # generate unique code
    code = generate_code()
    cur.execute("SELECT code FROM urls WHERE code = ?", (code,))
    while cur.fetchone():
        code = generate_code()

    cur.execute("INSERT INTO urls (code, url) VALUES (?, ?)", (code, url))
    conn.commit()
    conn.close()
    print(f"Shortened: {code}")

def get_url(code):
    conn = init_db()
    cur = conn.cursor()
    cur.execute("SELECT url FROM urls WHERE code = ?", (code,))
    row = cur.fetchone()
    conn.close()
    if row:
        print(f"Original: {row[0]}")
    else:
        print("Not found.")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: shorten [add|get] <url|code>")
        sys.exit(1)

    command, value = sys.argv[1], sys.argv[2]

    if command == "add":
        add_url(value)
    elif command == "get":
        get_url(value)
    else:
        print("Unknown command.")

