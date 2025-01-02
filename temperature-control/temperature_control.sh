#!/bin/bash

# check if PID is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <PID>"
    exit 1
fi

# get the PID of the process to monitor and control
PID=$1

# define the temperature threshold (in °C)
TEMP_THRESHOLD=85

# function to get the current temperature
get_temperature() {
    # extract the CPU package temperature from the `sensors` command output
    sensors | awk '/Package id 0/ {print $4}' | tr -d '+°C'
}

# function to pause the process
pause_process() {
    local pid=$1
    echo "Pausing process $pid..."
    kill -STOP "$pid"
}

# function to resume the process
resume_process() {
    local pid=$1
    echo "Resuming process $pid..."
    kill -CONT "$pid"
}

# main monitoring loop
while true; do
    current_temp=$(get_temperature)
    echo "Current temperature: $current_temp°C"

    if ! kill -0 "$PID" 2>/dev/null; then
        echo "Process with PID $PID is not running. Exiting."
        exit 1
    fi

    if (( $(echo "$current_temp > $TEMP_THRESHOLD" | bc -l) )); then
        echo "Temperature exceeds threshold ($TEMP_THRESHOLD°C)."
        pause_process "$PID"
        sleep 120
        resume_process "$PID"
    fi

    sleep 10 # check temperature every 10 seconds
done

