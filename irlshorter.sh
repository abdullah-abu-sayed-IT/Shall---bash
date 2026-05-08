#!/bin/bash

read -p "Enter Long URL: " LONG_URL

SHORT_URL=$(curl -s http://tinyurl.com/api-create.php?url=$LONG_URL)

echo "------------------------------------------"
echo "Original: $LONG_URL"
echo "Shortened: $SHORT_URL"
echo "------------------------------------------"
