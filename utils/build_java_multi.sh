#!/bin/bash

# Set script variables
DIR="$(dirname "${BASH_SOURCE[0]}")"
destination="data/sku.0/sys.server/compiled/game"
sourcepath="dsrc/sku.0/sys.server/compiled/game"

# Create necessary directories
mkdir -p "$destination/script"

# Find all Java files in the source path
readarray -d $'\0' filenames < <(find "$sourcepath" -name '*.java' -print0)
total=${#filenames[@]}
current=0

# Function to compile a Java file
compile() {
    local filename="$1"
    local OFILENAME="${filename/$sourcepath/$destination}"
    OFILENAME="${OFILENAME/java/class}"

    if [[ ! -e $OFILENAME || $filename -nt $OFILENAME ]]; then
        result=$("${DIR}/build_java_single.sh" "$filename" 2>&1)
        if [[ ! -z $result ]]; then
            printf "\r$filename\n$result\n\n"
        fi
    fi
}

# Loop through each Java file and compile in parallel with limited concurrency
for filename in "${filenames[@]}"; do
    compile "$filename" &

    # Update progress bar
    current=$((current + 1))
    perc=$((current * 100 / total))
    printf "\rCompiling java scripts: [%d%%]" "$perc"

    # Limit the number of concurrent jobs to improve efficiency
    while [[ $(jobs -p | wc -l) -ge 8 ]]; do
        sleep 1
    done
done

# Wait for all background jobs to complete
wait

# Print newline after completion
echo ""
