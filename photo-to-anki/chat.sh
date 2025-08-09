#!/bin/bash

# configurations
SCRIPT_DIR=$(dirname "$0")
COMMANDS_DIR="$SCRIPT_DIR/commands"
UTILS_DIR="$SCRIPT_DIR/utils"

echo "Welcome"
echo "Type /h for help with available commands."

while true; do
    read -p "> " USER_INPUT

    if [[ "$USER_INPUT" == "/q" ]]; then
        echo "Goodbye!"
        break
    fi

    COMMAND_FILE=$(bash "$UTILS_DIR/check_command_file.sh" "$USER_INPUT")
    if [[ -f "$COMMAND_FILE" ]]; then
        # execute the command
        bash "$COMMAND_FILE"
    else
        echo "Command not found. Type /h for help."
    fi

done


