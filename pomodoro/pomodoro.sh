#!/bin/bash

# Define the durations (in minutes)
FOCUS_TIME=1
SHORT_BREAK=1
LONG_BREAK=1

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
    paplay $1 &
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

while getopts ":f:" opt; do
    case $opt in
        f)
            TOTAL_FOCUS_PERIODS=$OPTARG
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

# Main Pomodoro loop
function pomodoro {
    local pomodoros_completed=0
    local total_focus_periods=0
    local total_short_breaks=0
    local total_long_breaks=0

    while true; do
        # Focus period
        ((total_focus_periods++))
        echo "Focus $total_focus_periods ($FOCUS_TIME minutes)"
        countdown $(minutes_to_seconds $FOCUS_TIME)
        notify_sound $FOCUS_END_SOUND

        # Check if the desired number of focus periods is reached
        if [ $TOTAL_FOCUS_PERIODS -ne 0 ] && [ $total_focus_periods -ge $TOTAL_FOCUS_PERIODS ]; then
            echo "Completed $TOTAL_FOCUS_PERIODS focus periods. Exiting."
            exit 0
        fi

        # Increment the pomodoros completed
        ((pomodoros_completed++))

        # Check if it's time for a long break
        if [ $pomodoros_completed -eq $POMODOROS_BEFORE_LONG_BREAK ]; then
            ((total_long_breaks++))
            echo "Long Break $total_long_breaks ($LONG_BREAK minutes)"
            countdown $(minutes_to_seconds $LONG_BREAK)
            echo "----------"
            notify_sound $BREAK_END_SOUND
           # pomodoros_completed=0
        else
            ((total_short_breaks++))
            echo "Short Break $total_short_breaks ($SHORT_BREAK minutes)"
            countdown $(minutes_to_seconds $SHORT_BREAK)
            echo "----------"
            notify_sound $BREAK_END_SOUND
        fi
    done
}

# Start the Pomodoro timer
pomodoro

