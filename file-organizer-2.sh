#!/bin/bash

#############################################
# File Organization Tool
# Organizes files into folders by type
# Usage: ./organize_files.sh [source_directory]
#############################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default directory is current directory
SOURCE_DIR="${1:-.}"

# Check if directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Error: Directory '$SOURCE_DIR' does not exist${NC}"
    exit 1
fi

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}     File Organization Tool v1.0${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${BLUE}Source Directory: $SOURCE_DIR${NC}\n"

# Define file categories and extensions
declare -A FILE_CATEGORIES=(
    [Documents]="pdf|doc|docx|txt|xlsx|xls|ppt|pptx|odt"
    [Images]="jpg|jpeg|png|gif|bmp|svg|webp|ico|tiff"
    [Videos]="mp4|mkv|avi|mov|flv|wmv|webm|m4v"
    [Audio]="mp3|wav|flac|aac|ogg|m4a|wma|aiff"
    [Archives]="zip|rar|7z|tar|gz|bz2|iso"
    [Code]="py|js|html|css|java|cpp|c|rb|php|go|rs|sh|json|xml|yaml"
    [Executables]="exe|bin|app|sh|bat|cmd"
    [Others]="*"
)

# Count statistics
declare -A MOVE_COUNT
TOTAL_FILES=0
TOTAL_MOVED=0

# Function to create directory if it doesn't exist
create_category_dir() {
    local category=$1
    local category_path="$SOURCE_DIR/$category"
    
    if [ ! -d "$category_path" ]; then
        mkdir -p "$category_path"
        echo -e "${GREEN}✓ Created directory: $category${NC}"
    fi
}

# Function to move files based on extension
organize_files() {
    local file=$1
    local filename=$(basename "$file")
    local extension="${filename##*.}"
    extension="${extension,,}"  # Convert to lowercase
    
    # Skip if file is in a subfolder already
    if [ -d "$file" ]; then
        return
    fi
    
    # Skip if file is the script itself
    if [ "$file" = "$SOURCE_DIR/organize_files.sh" ]; then
        return
    fi
    
    TOTAL_FILES=$((TOTAL_FILES + 1))
    
    # Find the category for this file
    local moved=false
    for category in "${!FILE_CATEGORIES[@]}"; do
        local extensions="${FILE_CATEGORIES[$category]}"
        
        if [[ "$extensions" == *"$extension"* ]] || [[ "$extensions" == "*" && "$moved" == "false" ]]; then
            local target_dir="$SOURCE_DIR/$category"
            
            # Don't move if already in target directory
            if [ "$(dirname "$file")" != "$target_dir" ]; then
                create_category_dir "$category"
                mv "$file" "$target_dir/"
                echo -e "${GREEN}✓${NC} Moved: ${YELLOW}$filename${NC} → ${BLUE}$category${NC}"
                
                MOVE_COUNT[$category]=$((${MOVE_COUNT[$category]:-0} + 1))
                TOTAL_MOVED=$((TOTAL_MOVED + 1))
                moved=true
            fi
            break
        fi
    done
}

# Main logic
echo -e "${YELLOW}Scanning files...${NC}\n"

# Process all files in the directory (not subdirectories)
while IFS= read -r -d '' file; do
    organize_files "$file"
done < <(find "$SOURCE_DIR" -maxdepth 1 -type f -print0)

# Display statistics
echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}            Statistics${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${BLUE}Total files found: ${NC}${YELLOW}$TOTAL_FILES${NC}"
echo -e "${BLUE}Total files moved: ${NC}${YELLOW}$TOTAL_MOVED${NC}\n"

if [ ${#MOVE_COUNT[@]} -gt 0 ]; then
    echo -e "${BLUE}Files per category:${NC}"
    for category in $(printf '%s\n' "${!MOVE_COUNT[@]}" | sort); do
        printf "  ${CYAN}%-15s${NC}: ${YELLOW}%d${NC} files\n" "$category" "${MOVE_COUNT[$category]}"
    done
fi

echo -e "\n${GREEN}✓ Organization complete!${NC}\n"

# Optional: Show directory tree
read -p "Show directory structure? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}Directory Structure:${NC}\n"
    tree "$SOURCE_DIR" -L 2 2>/dev/null || find "$SOURCE_DIR" -maxdepth 2 -type d | sort | sed 's|[^/]*/| |g'
fi
