#!/bin/bash
echo "--- System Info ---"
echo "User: $USER"
echo "Date: $(date)"
echo "Uptime: $(uptime -p)"
echo "Memory usage:"
free -h
