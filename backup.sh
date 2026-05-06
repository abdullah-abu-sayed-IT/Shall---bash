#!/bin/bash
read -p "Folder: " folder
tar -czf backup_$(date +%F).tar.gz $folder
echo "Backup created!"
