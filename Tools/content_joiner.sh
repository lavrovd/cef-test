#!/bin/bash

# This script combines the contents of files from one or more specified directories
# into a single output file. Each file's path is prepended to its content in the output.
# We use result as an input for LLM
# Usage:
#   ./combine_files.sh <output_file> <directory_to_process> [additional_directories...]
#
# Example:
#   ./combine_files.sh combined_templates.txt web cmd server
#
# This example combines files from 'web', 'cmd', and 'server' directories into 'combined_templates.txt'.

# Check if at least two arguments are provided (output file and at least one directory)
if [[ "$#" -lt 2 ]]; then
    echo "Usage: $0 <output_file> <directory_to_process> [additional_directories...]"
    exit 1
fi

# Assign the first argument as the output file name
output_file="$1"
shift  # Shift to process remaining arguments as directories

# Clear the output file if it exists, to start with an empty file
> "$output_file"

# Function to recursively process files in a directory
process_directory() {
    local dir_path="$1"
    for entry in "$dir_path"/*; do
        if [[ -d "$entry" ]]; then
            process_directory "$entry"
        elif [[ -f "$entry" ]]; then
            echo "Processing $entry"
            echo "=====================================================================" >> "$output_file"
            echo "FILE: $entry " >> "$output_file"  # Add file path as a header
            echo "=====================================================================" >> "$output_file"
            cat "$entry" >> "$output_file"  # Append file's content
            echo >> "$output_file"
            echo "=====================================================================" >> "$output_file"
            echo "EOF: $entry " >> "$output_file"  # Add file path as a header
            echo "=====================================================================" >> "$output_file"
        fi
    done
}

# Process each directory specified in the arguments
for directory_to_process in "$@"; do
    process_directory "$directory_to_process"
done

# Notify the user that the script has completed
echo "All files combined into $output_file"