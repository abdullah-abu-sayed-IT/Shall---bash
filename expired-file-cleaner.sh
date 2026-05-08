#!/bin/bash

read -p "Target directory path: " TARGET_DIR
read -p "Delete files older than (days): " DAYS

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory does not exist!"
    exit 1
fi

echo "Checking for files in $TARGET_DIR older than $DAYS days..."

FILES_TO_DELETE=$(find "$TARGET_DIR" -type f -mtime +$DAYS)

if [ -z "$FILES_TO_DELETE" ]; then
    echo "No expired files found."
else
    echo "The following files will be deleted:"
    echo "$FILES_TO_DELETE"
    
    read -p "Are you sure you want to delete these files? (y/n): " CONFIRM
    if [ "$CONFIRM" == "y" ]; then
        find "$TARGET_DIR" -type f -mtime +$DAYS -delete
        echo "✅ Expired files deleted successfully!"
    else
        echo "❌ Operation cancelled."
    fi
fi
