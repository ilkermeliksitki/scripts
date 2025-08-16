#!/usr/bin/env python3

import os
import sys
import subprocess
from pathlib import Path
from db.create_new_session import create_new_session
from db.summary.save_summary import save_summary
from services.summarization import summarize_most_recent
from utils.conversation.count_messages import count_messages
from utils.conversation.format_recent_messages import format_recent_messages

SCRIPT_DIR = Path(__file__).parent.resolve()
DATABASE_PATH = SCRIPT_DIR / "db" / "database.db"
DATABASE_INIT_SCRIPT = SCRIPT_DIR / "db" / "init_database.sh"
COMMANDS_DIR = SCRIPT_DIR / "commands"
UTILS_DIR = SCRIPT_DIR / "utils"

os.environ["SCRIPT_DIR"] = str(SCRIPT_DIR)
os.environ["DATABASE_PATH"] = str(DATABASE_PATH)

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
            recent_fmt_messages = format_recent_messages(SESSION_ID)
            user_input_with_context = f"{recent_fmt_messages}\nUser: {user_input}"
            subprocess.run(["bash", str(UTILS_DIR / "send_plain_message.sh"), user_input_with_context])

            # after sending a message, update the running summary every N messages
            try:
                n = int(os.getenv("SUMMARY_EVERY_N", "3"))
                total = count_messages(SESSION_ID)
                if total > 0 and total % n == 0:
                    new_summary = summarize_most_recent(limit=n)
                    if new_summary:
                        save_summary(new_summary)
            except Exception as e:
                print(f"Warning: failed to update running summary: {e}")


    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")

    except KeyboardInterrupt:
        print("\nGoodbye! 👋")
        break

    except EOFError:
        print("\nGoodbye! 👋")
        break
