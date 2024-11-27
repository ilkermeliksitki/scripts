#!/bin/bash

find_corrupt_csv() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: find_corrupt_csv <csv_file> [<csv_file2> ...]"
        return 1
    fi

    for file in "$@"; do
        if [[ ! -f $file ]]; then
            echo "Error: File '$file' does not exist or is not accessible."
            continue
        fi

        echo "Processing file: $file"

        # Detect the most common field count, handling quoted fields
        common_field_info=$(awk -v FPAT='([^,]+)|(\"[^\"]*\")' '{print NF}' "$file" | sort | uniq -c | sort -nr | head -1)
        common_field_count=$(echo "$common_field_info" | awk '{print $2}')
        common_field_count_occurrences=$(echo "$common_field_info" | awk '{print $1}')

        # Display the most common field count and its occurrence
        echo "Most Common Field Count: $common_field_count, $common_field_count_occurrences times"

        # Find and report lines with unexpected field counts
        invalid_lines=$(awk -v FPAT='([^,]+)|(\"[^\"]*\")' -v expected="$common_field_count" '
            NF != expected { print NR }
        ' "$file")

        if [[ -z "$invalid_lines" ]]; then
            echo "All lines are properly formatted."
        else
            echo "+-------+-------------+"
            echo "| Line  | Field Count |"
            echo "+-------+-------------+"
            # Print invalid lines and their field counts
            echo "$invalid_lines" | while read -r line; do
                field_count=$(awk -v FPAT='([^,]+)|(\"[^\"]*\")' "NR==$line {print NF}" "$file")
                if [[ "$field_count" -eq 0 ]]; then
                    printf "| %-5d | %-11d | <=== empty line\n" "$line" "$field_count"
                else
                    printf "| %-5d | %-11d |\n" "$line" "$field_count"
                fi
            done
            echo "+-------+-------------+"
        fi
    done
}

find_corrupt_csv "$@"
