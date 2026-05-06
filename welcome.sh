#!/bin/bash

USER_NAME=$USER
HOUR=$(date +%H)

if [ $HOUR -lt 12 ]; then
    GREETING="শুভ সকাল (Good Morning Abdullah sirrr)"
elif [ $HOUR -lt 18 ]; then
    GREETING="শুভ অপরাহ্ণ (Good Afternoon Abdullah sirrrr)"
else
    GREETING="শুভ সন্ধ্যা (Good Evening Abdullah sirrrrrr)"
fi

echo "------------------------------------------------"
echo "👋 $GREETING, $USER_NAME!"
echo "📅 তারিখ: $(date +'%A, %d %B %Y')"
echo "⏰ সময়: $(date +'%I:%M %p')"
echo "💻 আপটাইম: $(uptime -p)"
echo "🚀
