#!/bin/bash

# Define the durations (in minutes)
FOCUS_TIME=60
SHORT_BREAK=10
LONG_BREAK=30

# Define the number of Pomodoros before a long break
POMODOROS_BEFORE_LONG_BREAK=4

# Define the sound files for notifications
FOCUS_END_SOUND=/usr/share/sounds/freedesktop/stereo/complete.oga
BREAK_END_SOUND=/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga

# Function to convert minutes to seconds
function minutes_to_seconds {
    echo $(($1 * 60))
}

# Function to play sound notification
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
    local seconds=$1

    while [ $seconds -gt 0 ]; do
        echo -ne "$(date -u --date @$seconds +%H:%M:%S)\r"
        sleep 1
        : $((seconds--))
    done
    echo -ne "\033[2K\r"  # Clear the line after countdown is done
}

# Function to handle SIGINT (Ctrl+C)
function handle_sigint {
    echo -e "\nPomodoro timer interrupted. Exiting."
    exit 0
}

# Register SIGINT handler
trap handle_sigint SIGINT

# Parse command-line arguments
TOTAL_FOCUS_PERIODS=0

# get options f and l
while getopts ":f:l:" opt; do
    case $opt in
        f)
            TOTAL_FOCUS_PERIODS=$OPTARG
            ;;
        l)
            POMODOROS_BEFORE_LONG_BREAK=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

# Calculate the finish time
function calculate_finish_time {
    local focus_time=$1
    local short_break_time=$2
    local long_break_time=$3
    local total_focus_periods=$4
    local pomodoros_before_long_break=$5

    local total_seconds=0

    # Calculate total duration in seconds
    for ((i=1; i<=total_focus_periods; i++)); do
        total_seconds=$(($total_seconds + $(minutes_to_seconds $focus_time)))
        # Exclude the break after last focus time
        if (( $i < $total_focus_periods )); then
            # Choose long or short break
            if (( $i % $pomodoros_before_long_break == 0 )); then
                total_seconds=$(($total_seconds + $(minutes_to_seconds $long_break_time)))
            else
                total_seconds=$(($total_seconds + $(minutes_to_seconds $short_break_time)))
            fi
        fi
    done

    # Calculate finish time
    local finish_time=$(date -d "+$total_seconds seconds" +%H:%M:%S)
    echo "Expected finish time: $finish_time"
}

# Main Pomodoro loop
function pomodoro {
    local pomodoros_completed=0
    local total_focus_periods=0

    calculate_finish_time $FOCUS_TIME $SHORT_BREAK $LONG_BREAK $TOTAL_FOCUS_PERIODS $POMODOROS_BEFORE_LONG_BREAK

    while true; do
        # Focus period
        ((total_focus_periods++))
        echo "Focus $total_focus_periods ($FOCUS_TIME minutes)"
        countdown $(minutes_to_seconds $FOCUS_TIME)

        # Check if the desired number of focus periods is reached
        if [ $TOTAL_FOCUS_PERIODS -ne 0 ] && [ $total_focus_periods -ge $TOTAL_FOCUS_PERIODS ]; then
            echo "Completed $TOTAL_FOCUS_PERIODS focus periods. Exiting."
            notify_sound $FOCUS_END_SOUND # consider changing this to a different sound to indicate completion
            notify "critical" "Completed $TOTAL_FOCUS_PERIODS focus periods. Well done!"
            exit 0
        else
            notify_sound $FOCUS_END_SOUND
            notify "normal" "Focus $total_focus_periods completed. Take a break!"
        fi

        # Increment the pomodoros completed
        ((pomodoros_completed++))

        # Check if it's time for a long break
        if [ $(($pomodoros_completed % $POMODOROS_BEFORE_LONG_BREAK)) = 0 ]; then
            echo "Long Break ($LONG_BREAK minutes)"
            countdown $(minutes_to_seconds $LONG_BREAK)
            echo "----------"
            notify_sound $BREAK_END_SOUND
            notify "critical" "Long break is over. Time to focus!"
        else
            echo "Short Break ($SHORT_BREAK minutes)"
            countdown $(minutes_to_seconds $SHORT_BREAK)
            echo "----------"
            notify_sound $BREAK_END_SOUND
            notify "critical" "Short break is over. Time to focus!"
        fi
    done
}

# Start the Pomodoro timer
pomodoro
