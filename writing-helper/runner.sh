#!/bin/bash
export DISPLAY="${DISPLAY:-:0}" DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

PROMPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/prompts"

clip_get() { command -v xclip >/dev/null 2>&1 && xclip -sel clip -o 2>/dev/null || wl-paste 2>/dev/null; }
clip_set() { command -v xclip >/dev/null 2>&1 && printf "%s" "$1" | xclip -sel clip || printf "%s" "$1" | wl-copy; }

parse_prompt() {
    PROMPT_TITLE="" PROMPT_DESC="" PROMPT_TAGS="" PROMPT_ACTION="" PROMPT_BODY=""
    local fm=0 line
    while IFS= read -r line || [ -n "$line" ]; do
        if [ "$line" = "---" ]; then ((fm++)); continue; fi
        if [ $fm -eq 1 ]; then
            case "$line" in
                title:*) PROMPT_TITLE="${line#*: }" ;;
                description:*) PROMPT_DESC="${line#*: }" ;;
                tags:*) PROMPT_TAGS="${line#*: }" ;;
                action:*) PROMPT_ACTION="${line#*: }" ;;
            esac
        elif [ $fm -ge 2 ] && [ -n "$line" ]; then
            PROMPT_BODY="${PROMPT_BODY:+${PROMPT_BODY} }$line"
        fi
    done < "$1"
    : "${PROMPT_TITLE:=$(basename "$1" .md)}"
}

resolve_placeholders() {
    local clip
    clip="$(clip_get)"
    PROMPT_BODY="${PROMPT_BODY//\{\{clipboard\}\}/$clip}"

    while [[ "$PROMPT_BODY" =~ \{\{input:([^}]+)\}\} ]]; do
        local label="${BASH_REMATCH[1]}" match="${BASH_REMATCH[0]}" input
        input=$(printf "%s" "$clip" | rofi -dmenu -i -p "$label" -mesg "Enter value (or Enter for clipboard):") || return 1
        [ -z "$input" ] && return 1
        PROMPT_BODY="${PROMPT_BODY//"$match"/$input}"
    done
}

execute_prompt() {
    local file="$1" paste="${2:-0}"
    parse_prompt "$file" || return 1

    if [ "$PROMPT_ACTION" = "backtick_formatter" ]; then
        PROMPT_BODY="$(clip_get | sed -E "s/\`([^\`]+)\`/<span class='codei'>\1<\/span>/g")"
    else
        resolve_placeholders || { notify-send "Writing Helper" "Prompt cancelled"; return 1; }
    fi

    clip_set "$PROMPT_BODY"

    if [ "$paste" -eq 1 ] && command -v xdotool >/dev/null 2>&1; then
        sleep 0.2
        xdotool key --clearmodifiers ctrl+v
    fi

    notify-send "$([ "$paste" -eq 1 ] && echo "Copied & Pasted" || echo "Copied"): $PROMPT_TITLE" "${PROMPT_BODY:0:80}..."
}

show_preview() {
    parse_prompt "$1"
    printf "[Title]: %s\n[Description]: %s\n[Tags]: %s\n\n--- Content ---\n%s\n" \
        "$PROMPT_TITLE" "$PROMPT_DESC" "$PROMPT_TAGS" "$PROMPT_BODY" | \
        rofi -dmenu -i -p "Preview" -mesg "Enter: Execute | Esc: Return" -width 85 -lines 18 >/dev/null || return 1
    execute_prompt "$1" 0
}

show_menu() {
    command -v rofi >/dev/null 2>&1 || { notify-send "Writing Helper" "Rofi not installed"; exit 1; }
    local file_list=() rofi_rows=""
    for f in "$PROMPTS_DIR"/*.md; do
        [ -f "$f" ] || continue
        parse_prompt "$f"
        file_list+=("$f")
        printf -v row "%-30s | %-52s [%s]\n" "$PROMPT_TITLE" "$PROMPT_DESC" "$PROMPT_TAGS"
        rofi_rows+="$row"
    done

    while true; do
        local idx status
        idx=$(printf "%s" "$rofi_rows" | rofi -dmenu -i -format "i" -p "Writing Helper" \
            -mesg "Enter: Copy | Alt+Return: Paste | Alt+p: Preview | Esc: Cancel" \
            -kb-custom-1 "Alt+p" -kb-custom-2 "Alt+Return")
        status=$?

        [ $status -eq 1 ] || [ -z "$idx" ] && exit 0
        local chosen="${file_list[$idx]}"
        [ -f "$chosen" ] || exit 0

        if [ $status -eq 10 ]; then
            show_preview "$chosen" && exit 0
        else
            execute_prompt "$chosen" "$(( status == 11 ))"
            exit 0
        fi
    done
}

[ -f "$1" ] && execute_prompt "$1" "${2:-0}" || show_menu
