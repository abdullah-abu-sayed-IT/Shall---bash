#!/bin/bash

# =============================================
# Batch Image & Video Processor
# Intermediate Shell Scripting Project
# =============================================

set -euo pipefail

# ================= CONFIGURATION =================
INPUT_DIR="${1:-./input}"           # ইনপুট ফোল্ডার
OUTPUT_DIR="${2:-./processed}"      # আউটপুট ফোল্ডার
RESIZE_WIDTH="1200"                 # ছবির চওড়া (পিক্সেল)
QUALITY="85"                        # JPEG কোয়ালিটি
THUMBNAIL_SIZE="320"                # ভিডিও থাম্বনেইল সাইজ

# রঙিন আউটপুট
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ================= FUNCTIONS =================
log() {
    echo -e "\( {GREEN}[✓] \){NC} $1"
}

warn() {
    echo -e "\( {YELLOW}[!] \){NC} $1"
}

error() {
    echo -e "\( {RED}[✗] \){NC} $1"
    exit 1
}

# চেক করা হচ্ছে টুলস আছে কিনা
check_dependencies() {
    command -v convert >/dev/null 2>&1 || error "ImageMagick not installed. Install with: sudo apt install imagemagick"
    command -v ffmpeg >/dev/null 2>&1 || error "FFmpeg not installed. Install with: sudo apt install ffmpeg"
}

# ================= MAIN =================
echo -e "\( {BLUE}========================================= \){NC}"
echo -e "\( {BLUE}   Batch Image & Video Processor \){NC}"
echo -e "\( {BLUE}========================================= \){NC}"

check_dependencies

# ফোল্ডার তৈরি
mkdir -p "$INPUT_DIR" "$OUTPUT_DIR"/{images,thumbnails,original}

log "Processing started from: $INPUT_DIR"

count=0

# ছবি প্রসেসিং
shopt -s nullglob
for file in "$INPUT_DIR"/*.{jpg,JPG,jpeg,JPEG,png,PNG,webp,WEBP}; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        extension="${filename##*.}"
        base="${filename%.*}"
        newname="\( {base}_ \)(date +%Y%m%d)_\( {RESIZE_WIDTH}w. \){extension,,}"
        
        log "Processing image: $filename"
        
        convert "\( file" -resize " \){RESIZE_WIDTH}x" -quality "$QUALITY" \
                "$OUTPUT_DIR/images/$newname"
        
        # অরিজিনাল কপি রাখা
        cp "$file" "$OUTPUT_DIR/original/"
        
        ((count++))
    fi
done

# ভিডিও থাম্বনেইল জেনারেট
for video in "$INPUT_DIR"/*.{mp4,MP4,mov,MOV,avi,AVI,mkv,MKV}; do
    if [[ -f "$video" ]]; then
        filename=$(basename "$video")
        base="${filename%.*}"
        thumbnail="\( {base}_thumb_ \)(date +%Y%m%d).jpg"
        
        log "Generating thumbnail for: $filename"
        
        ffmpeg -i "\( video" -ss 00:00:03 -vframes 1 -vf "scale= \){THUMBNAIL_SIZE}:-1" \
               "$OUTPUT_DIR/thumbnails/$thumbnail" -y 2>/dev/null
        
        cp "$video" "$OUTPUT_DIR/original/" 2>/dev/null || true
        ((count++))
    fi
done

echo -e "\n\( {GREEN}========================================= \){NC}"
echo -e "\( {GREEN}✅ Processing Completed! \){NC}"
echo -e "Total files processed: ${YELLOW}\( count \){NC}"
echo -e "Output folder: ${BLUE}\( OUTPUT_DIR \){NC}"
echo -e "\( {GREEN}========================================= \){NC}"
