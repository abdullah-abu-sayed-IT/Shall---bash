#!/bin/bash

#############################################
# Website Health Monitor
# Monitors multiple URLs and logs downtime
# Usage: ./monitor.sh
#############################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
MONITOR_DIR="$HOME/.website_monitor"
LOG_DIR="$MONITOR_DIR/logs"
STATUS_FILE="$MONITOR_DIR/status.txt"
DOWNTIME_LOG="$MONITOR_DIR/downtime.log"
URLS_FILE="$MONITOR_DIR/urls.conf"
TIMEOUT=5  # Timeout in seconds
CHECK_INTERVAL=300  # Check every 5 minutes (in seconds)

# Initialize directories
init_directories() {
    mkdir -p "$MONITOR_DIR" "$LOG_DIR"
    
    # Create default urls.conf if it doesn't exist
    if [ ! -f "$URLS_FILE" ]; then
        cat > "$URLS_FILE" << EOF
# Website URLs to monitor
# Format: protocol://domain.com:port
https://google.com
https://github.com
https://example.com
EOF
        echo -e "${YELLOW}Created $URLS_FILE${NC}"
        echo -e "${CYAN}Please edit this file and add URLs to monitor${NC}"
    fi
}

# Function to check website status
check_url() {
    local url=$1
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $TIMEOUT "$url" 2>/dev/null)
    
    if [ "$response_code" -eq 200 ] || [ "$response_code" -eq 301 ] || [ "$response_code" -eq 302 ]; then
        echo "UP"
    else
        echo "DOWN:$response_code"
    fi
}

# Function to get response time
get_response_time() {
    local url=$1
    local response_time=$(curl -s -o /dev/null -w "%{time_total}" --connect-timeout $TIMEOUT "$url" 2>/dev/null)
    echo "$response_time"
}

# Function to log downtime
log_downtime() {
    local url=$1
    local status=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $url - $status" >> "$DOWNTIME_LOG"
}

# Function to send notification (email example)
send_notification() {
    local url=$1
    local status=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Email notification (requires mail command)
    if command -v mail &> /dev/null; then
        echo "Website down: $url ($status) at $timestamp" | \
        mail -s "Alert: $url is down" "$ADMIN_EMAIL" 2>/dev/null
    fi
    
    # Discord webhook (optional)
    # Uncomment and replace DISCORD_WEBHOOK_URL
    # if [ ! -z "$DISCORD_WEBHOOK_URL" ]; then
    #     curl -X POST "$DISCORD_WEBHOOK_URL" \
    #         -H 'Content-Type: application/json' \
    #         -d "{\"content\":\"🚨 Alert: $url is down ($status) at $timestamp\"}"
    # fi
}

# Function to update status file
update_status() {
    local url=$1
    local status=$2
    local response_time=$3
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Create entry
    local entry="$url|$status|$response_time|$timestamp"
    
    # Update or append
    if grep -q "^$url|" "$STATUS_FILE" 2>/dev/null; then
        sed -i.bak "s|^$url|.*|$entry|" "$STATUS_FILE"
    else
        echo "$entry" >> "$STATUS_FILE"
    fi
}

# Function to display dashboard
show_dashboard() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}            ${BLUE}Website Health Monitor Dashboard${NC}${CYAN}           ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Last Update: $(date '+%Y-%m-%d %H:%M:%S')${CYAN}                           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}\n"
    
    if [ ! -f "$STATUS_FILE" ]; then
        echo -e "${YELLOW}No status data available yet${NC}"
        return
    fi
    
    echo -e "${BLUE}Website${CYAN}                      Status     Response Time    Last Checked${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    
    while IFS='|' read -r url status response_time timestamp; do
        # Truncate URL for display
        display_url=$(printf "%-30s" "${url:0:30}")
        
        # Color code status
        if [[ $status == UP* ]]; then
            status_display=$(printf "${GREEN}%-10s${NC}" "✓ UP")
        else
            status_display=$(printf "${RED}%-10s${NC}" "✗ DOWN")
        fi
        
        # Format response time
        if [ -z "$response_time" ] || [ "$response_time" = "0" ]; then
            response_display="N/A"
        else
            response_display="${response_time}s"
        fi
        response_display=$(printf "%-15s" "$response_display")
        
        # Timestamp
        timestamp_display=$(printf "%-19s" "${timestamp:0:19}")
        
        echo -e "$display_url $status_display $response_display $timestamp_display"
    done < "$STATUS_FILE"
    
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}\n"
}

# Function to run continuous monitoring
run_monitor() {
    echo -e "${GREEN}Starting monitoring service...${NC}"
    echo -e "${CYAN}Check interval: ${TIMEOUT}s (connection timeout)${NC}"
    echo -e "${CYAN}Monitoring every: ${CHECK_INTERVAL}s${NC}\n"
    
    while true; do
        echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] Checking websites...${NC}"
        
        while IFS= read -r url; do
            # Skip empty lines and comments
            [ -z "$url" ] || [[ $url == \#* ]] && continue
            
            url=$(echo "$url" | xargs)  # Trim whitespace
            
            # Check status
            status=$(check_url "$url")
            response_time=$(get_response_time "$url")
            
            # Update status
            update_status "$url" "$status" "$response_time"
            
            # Log downtime and send alerts
            if [[ $status == DOWN* ]]; then
                log_downtime "$url" "$status"
                send_notification "$url" "$status"
                echo -e "  ${RED}✗ $url${NC} - ${RED}DOWN${NC}"
            else
                echo -e "  ${GREEN}✓ $url${NC} - ${GREEN}UP${NC} (${response_time}s)"
            fi
        done < "$URLS_FILE"
        
        # Show dashboard
        show_dashboard
        
        # Wait for next check
        echo -e "${CYAN}Next check in ${CHECK_INTERVAL}s. Press Ctrl+C to stop.${NC}"
        sleep "$CHECK_INTERVAL"
    done
}

# Function to show statistics
show_stats() {
    echo -e "\n${CYAN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}         Monitoring Statistics${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}\n"
    
    if [ ! -f "$DOWNTIME_LOG" ]; then
        echo -e "${YELLOW}No downtime recorded yet${NC}"
        return
    fi
    
    echo -e "${BLUE}Downtime Events:${NC}\n"
    tail -20 "$DOWNTIME_LOG"
    
    echo -e "\n${BLUE}Total downtime events: $(wc -l < "$DOWNTIME_LOG")${NC}\n"
}

# Function to view detailed log
view_detailed_log() {
    local url=$1
    
    if [ -z "$url" ]; then
        echo -e "${YELLOW}Please specify a URL${NC}"
        return
    fi
    
    local log_file="$LOG_DIR/$(echo $url | tr '/:' '_').log"
    
    if [ ! -f "$log_file" ]; then
        echo -e "${YELLOW}No log found for $url${NC}"
        return
    fi
    
    echo -e "${CYAN}Log for $url:${NC}\n"
    tail -50 "$log_file"
}

# Function to add URL
add_url() {
    read -p "$(echo -e ${GREEN}Enter URL to monitor:${NC}) " url
    
    if [ -z "$url" ]; then
        echo -e "${RED}URL cannot be empty${NC}"
        return
    fi
    
    if grep -q "^$url$" "$URLS_FILE"; then
        echo -e "${YELLOW}URL already exists${NC}"
        return
    fi
    
    echo "$url" >> "$URLS_FILE"
    echo -e "${GREEN}✓ URL added: $url${NC}"
}

# Function to remove URL
remove_url() {
    echo -e "${BLUE}URLs currently being monitored:${NC}\n"
    
    local count=0
    declare -a urls
    while IFS= read -r url; do
        [ -z "$url" ] || [[ $url == \#* ]] && continue
        count=$((count + 1))
        urls[$count]="$url"
        echo -e "${CYAN}$count)${NC} $url"
    done < "$URLS_FILE"
    
    echo
    read -p "$(echo -e ${YELLOW}Enter URL number to remove (0 to cancel):${NC}) " choice
    
    if [ "$choice" -eq 0 ] 2>/dev/null; then
        return
    fi
    
    if [ "$choice" -lt 1 ] || [ "$choice" -gt $count ] 2>/dev/null; then
        echo -e "${RED}Invalid selection${NC}"
        return
    fi
    
    local url_to_remove="${urls[$choice]}"
    sed -i.bak "\|^${url_to_remove}$|d" "$URLS_FILE"
    echo -e "${GREEN}✓ URL removed: $url_to_remove${NC}"
}

# Function to show menu
show_menu() {
    clear
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}   Website Health Monitor - Main Menu${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}\n"
    echo -e "${BLUE}1)${NC} Start monitoring (continuous)"
    echo -e "${BLUE}2)${NC} Check websites once"
    echo -e "${BLUE}3)${NC} View dashboard"
    echo -e "${BLUE}4)${NC} View statistics"
    echo -e "${BLUE}5)${NC} Add URL to monitor"
    echo -e "${BLUE}6)${NC} Remove URL from monitor"
    echo -e "${BLUE}7)${NC} View downtime log"
    echo -e "${RED}8)${NC} Exit\n"
}

# Main execution
init_directories

while true; do
    show_menu
    read -p "Enter choice (1-8): " choice
    
    case $choice in
        1)
            run_monitor
            ;;
        2)
            echo -e "\n${YELLOW}Checking websites...${NC}\n"
            while IFS= read -r url; do
                [ -z "$url" ] || [[ $url == \#* ]] && continue
                url=$(echo "$url" | xargs)
                
                status=$(check_url "$url")
                response_time=$(get_response_time "$url")
                update_status "$url" "$status" "$response_time"
                
                if [[ $status == DOWN* ]]; then
                    echo -e "${RED}✗ $url${NC} - DOWN"
                else
                    echo -e "${GREEN}✓ $url${NC} - UP (${response_time}s)"
                fi
            done < "$URLS_FILE"
            read -p "$(echo -e ${CYAN}Press Enter to continue...${NC})"
            ;;
        3)
            show_dashboard
            read -p "$(echo -e ${CYAN}Press Enter to continue...${NC})"
            ;;
        4)
            show_stats
            read -p "$(echo -e ${CYAN}Press Enter to continue...${NC})"
            ;;
        5)
            add_url
            read -p "$(echo -e ${CYAN}Press Enter to continue...${NC})"
            ;;
        6)
            remove_url
            read -p "$(echo -e ${CYAN}Press Enter to continue...${NC})"
            ;;
        7)
            echo -e "\n${CYAN}Downtime Log:${NC}\n"
            if [ -f "$DOWNTIME_LOG" ]; then
                tail -30 "$DOWNTIME_LOG"
            else
                echo -e "${YELLOW}No downtime logged yet${NC}"
            fi
            read -p "$(echo -e ${CYAN}Press Enter to continue...${NC})"
            ;;
        8)
            echo -e "${GREEN}Goodbye!${NC}\n"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            sleep 2
            ;;
    esac
done
