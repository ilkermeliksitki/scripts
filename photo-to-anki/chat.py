#!/usr/bin/env python3

import os
import sys
import subprocess
from pathlib import Path
from db.create_new_session import create_new_session
from utils.conversation.count_messages import count_messages
from utils.send_plain_message import send_plain_message

SCRIPT_DIR = Path(__file__).parent.resolve()
DATABASE_PATH = SCRIPT_DIR / "db" / "database.db"
DATABASE_INIT_SCRIPT = SCRIPT_DIR / "db" / "init_database.sh"
COMMANDS_DIR = SCRIPT_DIR / "commands"
UTILS_DIR = SCRIPT_DIR / "utils"
IMAGES_DIR = SCRIPT_DIR / "db" / "images"

os.environ["SCRIPT_DIR"] = str(SCRIPT_DIR)
os.environ["DATABASE_PATH"] = str(DATABASE_PATH)
os.environ["IMAGES_DIR"] = str(IMAGES_DIR)

SESSION_ID = create_new_session(DATABASE_PATH, DATABASE_INIT_SCRIPT)
os.environ["SESSION_ID"] = str(SESSION_ID)

print("Welcome 😊")
print("Type /h for help with available commands.")

while True:
    try:
        user_input = input("> ").strip()
        if not user_input:
            continue

        if user_input == "/q":
            print("Goodbye! 👋")
            break

        if user_input == "/h":
            help_file = subprocess.run(
                ["bash", str(COMMANDS_DIR / "help.sh")],
                capture_output=True, text=True).stdout.strip()
            print(help_file)
            continue

        if user_input.startswith("/"):
            command_file = subprocess.run(
                ["bash", str(UTILS_DIR / "check_command_file.sh"), user_input],
                capture_output=True, text=True).stdout.strip()

            if Path(command_file).is_file():
                # execute handlers according to their file type
                if command_file.endswith('.py'):
                    subprocess.run([sys.executable, command_file], check=True)
                else:
                    subprocess.run(["bash", command_file], check=True)
            else:
                print(f"Command not found. Type /h for help.")
        else:
            send_plain_message(user_input)

    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")

    except KeyboardInterrupt:
        print("\nGoodbye! 👋")
        break

    except EOFError:
        print("\nGoodbye! 👋")
        break
