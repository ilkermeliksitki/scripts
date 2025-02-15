#!/bin/bash

# Check if rclone is installed
check_rclone() {
    if ! command -v rclone &> /dev/null; then
        echo "Error: rclone is not installed. Please install rclone and try again."
        exit 1
    fi
}

# Get and validate arguments
get_and_check_args() {
    while getopts "s:d:h" arg; do
        case $arg in
            s)
                service=$OPTARG
                ;;
            d)
                destination=$OPTARG
                ;;
            h)
                echo "Usage: $0 -s <service:dropbox> -d <destination:local|cloud>"
                exit 0
                ;;
            ?)
                echo "Unknown argument: $arg"
                echo "Usage: $0 -s <service:dropbox> -d <destination:local|cloud>"
                exit 1
                ;;
        esac    
    done

    if [ -z "$service" ]; then
        echo "Error: Service argument is required. Use -s to specify it."
        exit 1
    fi

    if [ -z "$destination" ]; then
        echo "Error: Destination argument is required. Use -d to specify it."
        exit 1
    fi
}

# Main function
main() {
    check_rclone
    get_and_check_args "$@"
    echo "Service: $service"
    echo "Destination: $destination"
}

# Call main with all script arguments
main "$@"

