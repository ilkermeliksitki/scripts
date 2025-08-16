#!/bin/bash

# upload the configuration
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMMANDS_DIR="$SCRIPT_DIR/commands"

declare -A COMMAND_MAP
COMMAND_MAP["/i"]="image_input.py"     # Map `/i` to python image input
COMMAND_MAP["/a"]="anki.sh"         # Map `/a` to `anki.sh`
COMMAND_MAP["/h"]="help.sh"         # Map `/h` to `help.sh`

USER_INPUT="$1"

# check if the command is mapped
if [[ -n "${COMMAND_MAP[$USER_INPUT]}" ]]; then
    COMMAND_FILE="$COMMANDS_DIR/${COMMAND_MAP[$USER_INPUT]}"
    if [[ -f "$COMMAND_FILE" ]]; then
        echo "$COMMAND_FILE"  # stdout result for the caller
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
