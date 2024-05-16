#!/bin/bash

# Set script variables
destination="data/sku.0/sys.server/compiled/game"
sourcepath="dsrc/sku.0/sys.server/compiled/game"

# Create necessary directories if they don't exist
mkdir -p "$destination/script"

# Function to compile Java file
compile_java() {
    local filename="$1"

    # Check if the file exists and is a Java source file
    if [[ ! -f "$filename" || "${filename##*.}" != "java" ]]; then
        echo "Error: '$filename' is not a valid Java source file."
        return 1
    fi

    # Compile Java file with specified options
    javac -Xlint:-options -encoding utf8 -classpath "$destination" -d "$destination" -sourcepath "$sourcepath" -g -deprecation "$filename"
}

# Check if a file argument is provided
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <JavaFile>"
    exit 1
fi

# Loop through each provided Java file and compile
for file in "$@"; do
    compile_java "$file"
done
