#!/bin/bash

URL="https://abdullah-abu-sayed-it.github.io/"
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")

echo "------------------------------------------"
echo "URL: $URL"
echo "Time: $(date)"
echo "------------------------------------------"

if [ "$STATUS_CODE" -eq 200 ]; then
    echo "✅ Status: UP (Code: $STATUS_CODE)"
elif [ "$STATUS_CODE" -eq 301 ] || [ "$STATUS_CODE" -eq 302 ]; then
    echo "↪️ Status: REDIRECT (Code: $STATUS_CODE)"
else
    echo "❌ Status: DOWN/ERROR (Code: $STATUS_CODE)"
fi
echo "------------------------------------------"
