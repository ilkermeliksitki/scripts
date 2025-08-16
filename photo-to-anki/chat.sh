#!/bin/bash

# configurations
SCRIPT_DIR=$(dirname "$0")
export SCRIPT_DIR="$SCRIPT_DIR"
export DATABASE_PATH="$SCRIPT_DIR/db/database.db"

# add script directory to python path
export PYTHONPATH="$SCRIPT_DIR:$PYTHONPATH"

COMMANDS_DIR="$SCRIPT_DIR/commands"
UTILS_DIR="$SCRIPT_DIR/utils"
export SESSION_ID=$(python3 db/create_new_session.py)
echo "Session ID: $SESSION_ID"

echo "Welcome 😊"
echo "Type /h for help with available commands."

while true; do
    read -p "> " USER_INPUT

    if [[ -z "$USER_INPUT" ]]; then
        continue
    fi

    if [[ "$USER_INPUT" == "/q" ]]; then
        echo "Goodbye!"
        break
    fi

    # if it starts with /, treat it as a command
    if [[ "$USER_INPUT" == /* ]]; then
        COMMAND_FILE=$(bash "$UTILS_DIR/check_command_file.sh" "$USER_INPUT")
        if [[ -f "$COMMAND_FILE" ]]; then
            # execute the command
            bash "$COMMAND_FILE"
        else
            echo "Command not found. Type /h for help."
        fi
    else
        # treat it as a regular message
        bash "$UTILS_DIR/send_plain_message.sh" "$USER_INPUT"
    fi

    summary=$(python3 db/summary/running_summary_per_session.py)
    printf "\nSummary:\n%s\n" "$summary"
    python3 db/summary/save_summary.py "$summary"
done
