#!/bin/bash
# 2024, Álex Pérez-Sánchez, MolBioMed Research Group, Univ. Autònoma de Barcelona

# Default values
max_value=100
destination_directory="selection"
source_directory="."

# Function to display help message
display_help() {
  echo "Usage: $0 [-m MAX_VALUE] [-d DESTINATION_DIRECTORY] [SOURCE_DIRECTORY]"
  echo "Copy asmd_*.work.dat files with the last column value less than MAX_VALUE to DESTINATION_DIRECTORY."
  echo ""
  echo "Options:"
  echo "  -m MAX_VALUE              Maximum value for the last column (default: 100)"
  echo "  -d DIRECTORIES            Destination and soruce directories (default: selection and working directories)"
  echo "  -h                        Display this help message"
  exit 1
}

# Parse command-line arguments
while getopts ":m:d:h" opt; do
  case $opt in
    m)
      max_value="$OPTARG"
      ;;
    d)
      destination_directory="$OPTARG"
      ;;
    h)
      display_help
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

# Shift the parsed options out of the command line arguments
shift $((OPTIND-1))

# Use the remaining arguments as the source directory (optional)
if [ "$#" -eq 1 ]; then
  source_directory="$1"
fi

# Validate destination directory argument
if [ ! -d "$destination_directory" ]; then
  mkdir -p "$destination_directory" || { echo "Error: Could not create destination directory '$destination_directory'."; exit 1; }
fi

# Validate source directory argument
if [ ! -d "$source_directory" ]; then
  echo "Error: Source directory '$source_directory' does not exist."
  display_help
fi

# Iterate over the asmd_*.work.dat files in the source directory
for file in "$source_directory"/asmd_*.work.dat; do
    # Get the last column value from the last line of the file
    last_column=$(awk 'END{print $NF}' "$file")

    # Check if the last column value is less than the specified maximum
    if [ "$(echo "$last_column < $max_value" | bc -l)" -eq 1 ]; then
        # Copy the file to the destination directory
        cp "$file" "$destination_directory"
        echo "Copied $file to $destination_directory"
    fi
done

