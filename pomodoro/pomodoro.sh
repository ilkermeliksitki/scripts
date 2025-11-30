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
NAG_SOUND="$SCRIPT_DIR/sounds/nagging.wav"

# add dependency check for paplay and notify-send
function check_dependencies {
    if ! command -v paplay &> /dev/null
    then
        echo "paplay could not be found, please install it."
        exit 1
    fi

    if ! command -v notify-send &> /dev/null
    then
        echo "notify-send could not be found, please install it."
        exit 1
    fi
}

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
    local timeout=${4:-60}

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
        notify_sound $NAG_SOUND # Use a short sound for nagging
        notify "critical" "Waiting for your input..."
    done
    
    # strip ansi color codes from input to ensure we get clean values
    input=$(echo "$input" | sed 's/\x1b\[[0-9;]*m//g')
    
    eval $var_name="'$input'"
}

# helper to get valid numeric input
function get_valid_number {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local min="$4"
    local max="$5"
    local val=""

    while true; do
        get_input "$prompt" "$default" val
        if [[ "$val" =~ ^[0-9]+$ ]]; then
            if [[ -n "$min" ]] && [ "$val" -lt "$min" ]; then
                 echo "$(color_red "Please enter a number >= $min")"
                 continue
            fi
            if [[ -n "$max" ]] && [ "$val" -gt "$max" ]; then
                 echo "$(color_red "Please enter a number <= $max")"
                 continue
            fi
            break
        else
             echo "$(color_red "Invalid number. Please try again.")"
        fi
    done

    eval $var_name="'$val'"
}

# log session to file
function log_session {
    local type="$1"
    local description="$2"
    local duration="$3"
    local energy="$4"
    local phase="$5"
    local suggested_focus="$6"
    local suggested_break="$7"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$timestamp | Type: $type | Description: $description | Duration: ${duration}m | Energy: $energy | Phase: $phase | Suggested: ${suggested_focus}m/${suggested_break}m" >> "$SESSION_LOG"
}

# determine phase and suggested times based on elapsed minutes
function get_phase_suggestion {
    local elapsed="$1"
    local energy="$2" # 1-5 scale
    # Sanitize energy (remove non-digits)
    energy=${energy//[^0-9]/}
    local current_hour=$(date +%H)

    # priority 1: the hard reset
    # if over 4 hours deep and low energy, force a long break
    if [ $elapsed -gt 240 ] && [ $energy -le 2 ]; then
        echo "0 30 The_Reset_(Burnout_Prev)"
        return
    fi

    # priority 2: energy & flow adaptation
    if [ "$energy" -eq 5 ]; then
        echo "60 10 Flow_State"
        return
    elif [ "$energy" -eq 1 ]; then
        echo "15 5 Survival_Mode"
        return
    fi

    # priority 3: circadian rhythm (afternoon slump protection)
    # between 14:00 (2pm) and 16:00 (4pm), reduce load
    if [ "$current_hour" -ge 14 ] && [ "$current_hour" -lt 16 ]; then
        echo "25 5 Afternoon_Slump_Protection"
        return
    fi

    # priority 4: standard ramp-up
    if [ $elapsed -lt 120 ]; then
        echo "25 5 High_Urgency"
    elif [ $elapsed -lt 240 ]; then
        echo "50 10 Deep_Work"
    elif [ $elapsed -lt 360 ]; then
        # prevent infinite loop
        echo "30 10 Taper_Down"
    else
        # after 6 hours, switch to maintenance mode to maintain quality
        echo "25 5 Maintenance_Mode"
    fi
}

# Color helpers
function color_red    { echo -ne "\033[1;31m$1\033[0m"; }
function color_green  { echo -ne "\033[1;32m$1\033[0m"; }
function color_brown  { echo -ne "\033[1;33m$1\033[0m"; }
function color_blue   { echo -ne "\033[1;34m$1\033[0m"; }
function color_purple { echo -ne "\033[1;35m$1\033[0m"; }
function color_36     { echo -ne "\033[1;36m$1\033[0m"; }
function color_52     { echo -ne "\033[1;52m$1\033[0m"; }
function color_yellow { echo -ne "\033[1;93m$1\033[0m"; }
function color_cyan   { echo -ne "\033[1;96m$1\033[0m"; }

# Clear lines helper
function clear_lines {
    local count=${1:-1}
    for ((i=0; i<count; i++)); do
        echo -ne "\033[1A\033[2K"
    done
}

# main pomodoro loop
function pomodoro {
    local total_elapsed=0
    local previous_goal=""
    local current_energy=""

    check_dependencies

    echo "$(color_36 "Welcome to the Adaptive Pomodoro Timer!")"
    
    while true; do
        echo -e "\n========================================"
        
        # check energy level
        get_valid_number "$(color_yellow "Current Energy Level (1=Drained, 5=Flow)")" "$(color_52 "3")" current_energy 1 5
        
        # adaptive logic & suggestions
        read suggest_focus suggest_break phase_name <<< $(get_phase_suggestion $total_elapsed $current_energy)
        
        # format phase name (replace underscores with spaces)
        display_phase="${phase_name//_/ }"
        
        if [[ "$phase_name" == *"The_Reset"* ]]; then
             echo "$(color_blue "Phase:") $(color_red " $display_phase") $(color_52 "(Elapsed: ${total_elapsed}m)")"
             echo "$(color_blue "Suggestion:") $(color_red "Take a long break!")"
        else
             echo "$(color_blue "Phase:") $(color_red " $display_phase") $(color_52 "(Elapsed: ${total_elapsed}m)")"
             echo "$(color_blue "Suggested:") $(color_red "Focus ${suggest_focus}m / Break ${suggest_break}m")"
        fi
        
        # goal setting & confirmation
        while true; do
            get_input "$(color_yellow "Enter Focus Goal (or 'exit' to quit)")" "$previous_goal" current_goal
            
            if [ "$current_goal" == "exit" ]; then
                echo "Goodbye!"
                exit 0
            fi
            
            if [ ${#current_goal} -ge 10 ]; then
                break
            fi
            
            echo "Goal too short. Please be more specific (min 10 chars)."
            notify_sound $NAG_SOUND
        done
        
        # update previous goal
        previous_goal="$current_goal"

        get_valid_number "Focus Duration (min)" "$suggest_focus" current_focus_time 1
        
        if [ "$current_focus_time" -gt 0 ]; then
            log_session "Focus" "$current_goal" "$current_focus_time" "$current_energy" "$phase_name" "$suggest_focus" "$suggest_break"
            
            # focus timer
            echo -e "\n>>> $(color_blue "Focus"): $(color_green "$current_goal") ($current_focus_time min)"
            notify "normal" "Focus: $current_goal"
            countdown $(minutes_to_seconds $current_focus_time)
            
            total_elapsed=$((total_elapsed + current_focus_time))
            notify_sound $FOCUS_END_SOUND
            notify "critical" "Focus complete! Time to take a break."
        fi

        # break logic
        get_input "Take a break?" "y" take_break
        clear_lines 1

        if [ "$take_break" != "n" ]; then
             get_input "Break Activity" "rest" break_activity
             get_input "Break Duration (min)" "$suggest_break" current_break_time
             
             log_session "Break" "$break_activity" "$current_break_time" "$current_energy" "$phase_name" "$suggest_focus" "$suggest_break"

             echo -e "\n>>> $(color_brown "Break:") $(color_green "$break_activity") ($current_break_time min)"
             countdown $(minutes_to_seconds $current_break_time)
             
             if [ "$current_break_time" -ge 20 ]; then
                 notify_sound $LONG_BREAK_END_SOUND
             else
                 notify_sound $SHORT_BREAK_END_SOUND
             fi
             notify "critical" "Break over! Ready to focus?"
        fi
        
        # wait for next loop
        get_input "Next session?" "y" next_session
        clear_lines 1
    done
}

# start the pomodoro timer only if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pomodoro
fi