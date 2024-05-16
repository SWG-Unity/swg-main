#!/bin/bash

get_current_branch() {
    git --git-dir=dsrc/.git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,'
}

# Initialize variables
CBRANCH=$(get_current_branch)
DIR="$(dirname "${BASH_SOURCE[0]}")"
WDIR="$(pwd)"
destination="data/sku.0/sys.server/compiled/game"
sourcepath="dsrc/sku.0/sys.server/compiled/game"
spinstr='|/-\'
i=0
current=0

# Create directory structure
mkdir -p "$destination/script"

# Array to hold scriptlib constants that need recompilation
declare -A items=()

# Function to compile Java file
compile_java_file() {
    local filename=$1
    local OFILENAME=${filename/$sourcepath/$destination}
    OFILENAME=${OFILENAME/java/class}

    if [[ ! -e $OFILENAME || $filename -nt $OFILENAME ]]; then
        result=$(${DIR}/build_java_single.sh "$filename" 2>&1)
        if [[ ! -z $result ]]; then
            printf "\r$filename\n$result\n\n"
        fi

        # Extract constant declarations from git diff
        git --git-dir="$WDIR/dsrc/.git" --work-tree="$WDIR/dsrc" diff "origin/$CBRANCH" -U0 | grep -o "public static final .*=" | while read -r line; do
            local const_name=$(echo "$line" | awk '{print $4}' | sed 's/=$//')
            echo "Library CONST - recompiling $const_name"
            items["$const_name"]=1
        done
    fi

    current=$((current + 1))
    i=$(( (i + 1) % 4 ))
    perc=$((current * 100 / total))
    printf "\rCompiling Java scripts: [${spinstr:i:1}] $perc%%"
}

# Find Java files and process each one
mapfile -t filenames < <(find "$sourcepath" -name '*.java')

total=${#filenames[@]}

for filename in "${filenames[@]}"; do
    compile_java_file "$filename"
done

# Recompile scripts using scriptlib constants
for item in "${!items[@]}"; do
    item=${item#"./"}
    $WDIR/utils/build_java_single.sh "$WDIR/dsrc/sku.0/sys.server/compiled/game/script/$item"
done

echo ""  # Print newline after completion
