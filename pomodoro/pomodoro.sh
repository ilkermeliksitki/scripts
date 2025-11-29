#!/bin/bash

get_script_dir() {
    # resolve the directory of the script (following symlinks if any)
    local SOURCE="${BASH_SOURCE[0]}"
    while [ -L "$SOURCE" ]; do
        local TARGET="$(readlink "$SOURCE")"
        if [[ $TARGET == /* ]]; then
            # if symbolic link is created with absolute path, grab it
            SOURCE="$TARGET"
        else
            # if symbolic link is created with relative path, resolve it
            SOURCE="$(dirname "$SOURCE")/$TARGET"
        fi
    done
    cd "$(dirname "$SOURCE")" && pwd
}

# script directory
SCRIPT_DIR=$(get_script_dir)

# define the sound files for notifications
FOCUS_END_SOUND="$SCRIPT_DIR/sounds/focus_end.wav"
SHORT_BREAK_END_SOUND="$SCRIPT_DIR/sounds/short_break_end.wav"
LONG_BREAK_END_SOUND="$SCRIPT_DIR/sounds/long_break_end.wav"
CELEBRATION_SOUND="$SCRIPT_DIR/sounds/celebration.wav"

# add dependency check for paplay and notify-send
if ! command -v paplay &> /dev/null
then
    echo "paplay could not be found, please install it."
    exit
fi

if ! command -v notify-send &> /dev/null
then
    echo "notify-send could not be found, please install it."
    exit
fi

# function to convert minutes to seconds
function minutes_to_seconds {
    echo $(($1 * 60))
}

# function to play sound notification
function notify_sound {
    # play the sound at the background
    paplay $1 &
}

# Function to display notification
function notify {
    local urgency=${1}
    local message=${2}
    notify-send -u $urgency "Pomodoro" "$message"
}

# Function to display countdown timer
function countdown {
    local total_seconds=$1
    local seconds=$1
    local bar_length=30

    while [ $seconds -gt 0 ]; do
        local elapsed=$(($total_seconds - $seconds))
        local percent=$(($elapsed * 100 / $total_seconds))
        local filled=$(($percent * $bar_length / 100))
        local empty=$(($bar_length - $filled))

        local filled_bar=""
        for ((i=0; i<filled; i++)); do filled_bar+="#"; done
        local empty_bar=""
        for ((i=0; i<empty; i++)); do empty_bar+="-"; done

        # Print time, newline, bar, then move cursor up one line
        echo -ne "$(date -u --date @$seconds +%H:%M:%S) remaining\n[${filled_bar}${empty_bar}] ${percent}%\033[1A\r"
        sleep 1
        : $((seconds--))
    done
    echo -ne "\033[2K\n\033[2K\033[1A\r"
}

# Function to handle SIGINT (Ctrl+C)
function handle_sigint {
    echo -e "\nPomodoro timer interrupted. Exiting."
    exit 0
}

# register SIGINT handler
trap handle_sigint SIGINT

# session log
SESSION_LOG="$SCRIPT_DIR/session_log.log"

# helper to get user input with default value and nagging
function get_input {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local input=""
    local timeout=${4:-30}
    
    while true; do
        if [ -n "$default" ]; then
            # prompt with default
            if read -t $timeout -e -p "$prompt [$default]: " input; then
                : ${input:=$default}
                break
            fi
        else
            # prompt without default
            if read -t $timeout -e -p "$prompt: " input; then
                break
            fi
        fi
        
        # timeout reached (exit code > 128 usually, but read -t returns failure)
        # nag the user
        notify_sound $SHORT_BREAK_END_SOUND # Use a short sound for nagging
        notify "critical" "Waiting for your input..."
    done
    
    eval $var_name="'$input'"
}

# log session to file
function log_session {
    local goal="$1"
    local duration="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$timestamp | Goal: $goal | Duration: ${duration}m" >> "$SESSION_LOG"
}

# determine phase and suggested times based on elapsed minutes
function get_phase_suggestion {
    local elapsed=$1
    # returns: focus_time break_time phase_name
    if [ $elapsed -lt 120 ]; then
        echo "25 5 High Urgency"
    elif [ $elapsed -lt 360 ]; then
        echo "50 10 Deep Work"
    elif [ $elapsed -lt 420 ]; then
        echo "0 45 The Reset" # Suggesting a long break, 0 focus implies we might want to skip straight to break or just handle it manually
    else
        echo "45 15 Maintenance"
    fi
}

# main pomodoro loop
function pomodoro {
    local total_elapsed=0
    local previous_goal=""
    
    echo "Welcome to the Adaptive Pomodoro Timer!"
    
    while true; do
        echo -e "\n========================================"
        
        # adaptive logic & suggestions
        read suggest_focus suggest_break phase_name <<< $(get_phase_suggestion $total_elapsed)
        
        if [ "$phase_name" == "The Reset" ]; then
             echo "Phase: $phase_name (Elapsed: ${total_elapsed}m)"
             echo "Suggestion: Take a long break!"
             suggest_focus=0
             suggest_break=45
        else
             echo "Phase: $phase_name (Elapsed: ${total_elapsed}m)"
             echo "Suggested: Focus ${suggest_focus}m / Break ${suggest_break}m"
        fi
        
        # goal setting & confirmation
        while true; do
            get_input "Enter Focus Goal (or 'exit' to quit)" "$previous_goal" current_goal
            
            if [ "$current_goal" == "exit" ]; then
                echo "Goodbye!"
                exit 0
            fi
            
            if [ ${#current_goal} -ge 10 ]; then
                break
            fi
            
            echo "Goal too short. Please be more specific (min 10 chars)."
            notify_sound $SHORT_BREAK_END_SOUND
        done
        
        # update previous goal
        previous_goal="$current_goal"

        get_input "Focus Duration (min)" "$suggest_focus" current_focus_time
        
        if [ "$current_focus_time" -gt 0 ]; then
            log_session "$current_goal" "$current_focus_time"
            
            # focus timer
            echo -e "\n>>> Starting Focus: $current_goal ($current_focus_time min)"
            notify "normal" "Starting Focus: $current_goal"
            countdown $(minutes_to_seconds $current_focus_time)
            
            total_elapsed=$((total_elapsed + current_focus_time))
            notify_sound $FOCUS_END_SOUND
            notify "critical" "Focus complete! Time to take a break."
        fi

        # break logic
        get_input "Take a break?" "y" take_break
        if [ "$take_break" != "n" ]; then
             get_input "Break Duration (min)" "$suggest_break" current_break_time
             
             echo -e "\n>>> Starting Break ($current_break_time min)"
             countdown $(minutes_to_seconds $current_break_time)
             
             if [ "$current_break_time" -ge 20 ]; then
                 notify_sound $LONG_BREAK_END_SOUND
             else
                 notify_sound $SHORT_BREAK_END_SOUND
             fi
             notify "critical" "Break over! Ready to focus?"
        fi
        
        # wait for next loop
        echo -e "\n"
        read -p "Press Enter to continue to next session..."
        echo -ne "\033[1A\033[2K" # clear the prompt line
        echo -ne "\033[1A\033[2K" # clear the empty line
    done
}

# start the pomodoro timer
pomodoro
