#!/bin/bash

FILES_TO_CHECK=("todo.txt" "scanner.sh" "web_check.sh")
HASH_FILE="file_hashes.txt"

generate_hashes() {
    > "$HASH_FILE"
    for file in "${FILES_TO_CHECK[@]}"; do
        if [ -f "$file" ]; then
            sha256sum "$file" >> "$HASH_FILE"
        fi
    done
    echo "✅ Hashes generated."
}

check_integrity() {
    if [ ! -f "$HASH_FILE" ]; then
        echo "❌ Hash file not found! Run with --init first."
        exit 1
    fi

    while read -r line; do
        stored_hash=$(echo "$line" | awk '{print $1}')
        file=$(echo "$line" | awk '{print $2}')

        if [ -f "$file" ]; then
            current_hash=$(sha256sum "$file" | awk '{print $1}')
            if [ "$stored_hash" == "$current_hash" ]; then
                echo "✅ $file: OK"
            else
                echo "⚠️ ALERT: $file has been MODIFIED!"
            fi
        else
            echo "❌ $file: MISSING!"
        fi
    done < "$HASH_FILE"
}

if [ "$1" == "--init" ]; then
    generate_hashes
else
    check_integrity
fi
