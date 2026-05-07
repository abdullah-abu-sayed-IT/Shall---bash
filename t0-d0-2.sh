#!/bin/bash

#############################################
# To-Do List Manager
# Simple task management system
# Usage: ./todo.sh
#############################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Todo file location
TODO_FILE="$HOME/.todo_list"
COMPLETED_FILE="$HOME/.todo_completed"

# Initialize files if they don't exist
touch "$TODO_FILE" "$COMPLETED_FILE"

# Function to display header
show_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}        ${MAGENTA}TO-DO LIST MANAGER${NC}${CYAN}            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}\n"
}

# Function to display menu
show_menu() {
    echo -e "${YELLOW}What would you like to do?${NC}\n"
    echo -e "${BLUE}1)${NC} Add a new task"
    echo -e "${BLUE}2)${NC} View all tasks"
    echo -e "${BLUE}3)${NC} Mark task as complete"
    echo -e "${BLUE}4)${NC} Delete a task"
    echo -e "${BLUE}5)${NC} View completed tasks"
    echo -e "${BLUE}6)${NC} Clear all completed tasks"
    echo -e "${BLUE}7)${NC} Get statistics"
    echo -e "${RED}8)${NC} Exit\n"
}

# Function to add task
add_task() {
    show_header
    read -p "$(echo -e ${GREEN}Enter your task:${NC}) " task
    
    if [ -z "$task" ]; then
        echo -e "${RED}✗ Task cannot be empty!${NC}"
        sleep 2
        return
    fi
    
    # Add timestamp and task to file
    echo "[ ] $(date '+%Y-%m-%d %H:%M') - $task" >> "$TODO_FILE"
    echo -e "${GREEN}✓ Task added successfully!${NC}"
    sleep 2
}

# Function to view all tasks
view_tasks() {
    show_header
    
    if [ ! -s "$TODO_FILE" ]; then
        echo -e "${YELLOW}No tasks yet. Add one to get started!${NC}"
        sleep 2
        return
    fi
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}PENDING TASKS${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    local count=0
    while IFS= read -r line; do
        count=$((count + 1))
        # Extract just the task part (remove timestamp)
        task_text=$(echo "$line" | sed 's/\[ \] [0-9-]* [0-9:]* - //')
        echo -e "${CYAN}$count)${NC} ${YELLOW}☐${NC} $task_text"
    done < "$TODO_FILE"
    
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "$(echo -e ${CYAN}Press Enter to continue...${NC})" 
}

# Function to mark task as complete
mark_complete() {
    show_header
    
    if [ ! -s "$TODO_FILE" ]; then
        echo -e "${YELLOW}No pending tasks!${NC}"
        sleep 2
        return
    fi
    
    echo -e "${BLUE}Select task to mark as complete:${NC}\n"
    
    local count=0
    declare -a tasks
    while IFS= read -r line; do
        count=$((count + 1))
        tasks[$count]="$line"
        task_text=$(echo "$line" | sed 's/\[ \] [0-9-]* [0-9:]* - //')
        echo -e "${CYAN}$count)${NC} $task_text"
    done < "$TODO_FILE"
    
    echo
    read -p "$(echo -e ${GREEN}Enter task number (0 to cancel):${NC}) " task_num
    
    if [ "$task_num" -eq 0 ] 2>/dev/null; then
        return
    fi
    
    if [ "$task_num" -lt 1 ] || [ "$task_num" -gt $count ] 2>/dev/null; then
        echo -e "${RED}✗ Invalid selection!${NC}"
        sleep 2
        return
    fi
    
    # Mark as complete
    local completed_task="${tasks[$task_num]}"
    completed_task="[✓] ${completed_task#'[ ] '}"
    
    echo "$completed_task" >> "$COMPLETED_FILE"
    
    # Remove from todo
    sed -i "${task_num}d" "$TODO_FILE"
    
    echo -e "${GREEN}✓ Task marked as complete!${NC}"
    sleep 2
}

# Function to delete task
delete_task() {
    show_header
    
    if [ ! -s "$TODO_FILE" ]; then
        echo -e "${YELLOW}No tasks to delete!${NC}"
        sleep 2
        return
    fi
    
    echo -e "${BLUE}Select task to delete:${NC}\n"
    
    local count=0
    while IFS= read -r line; do
        count=$((count + 1))
        task_text=$(echo "$line" | sed 's/\[ \] [0-9-]* [0-9:]* - //')
        echo -e "${CYAN}$count)${NC} $task_text"
    done < "$TODO_FILE"
    
    echo
    read -p "$(echo -e ${RED}Enter task number to delete (0 to cancel):${NC}) " task_num
    
    if [ "$task_num" -eq 0 ] 2>/dev/null; then
        return
    fi
    
    if [ "$task_num" -lt 1 ] || [ "$task_num" -gt $count ] 2>/dev/null; then
        echo -e "${RED}✗ Invalid selection!${NC}"
        sleep 2
        return
    fi
    
    sed -i "${task_num}d" "$TODO_FILE"
    echo -e "${GREEN}✓ Task deleted!${NC}"
    sleep 2
}

# Function to view completed tasks
view_completed() {
    show_header
    
    if [ ! -s "$COMPLETED_FILE" ]; then
        echo -e "${YELLOW}No completed tasks yet!${NC}"
        sleep 2
        return
    fi
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}COMPLETED TASKS${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    local count=0
    while IFS= read -r line; do
        count=$((count + 1))
        task_text=$(echo "$line" | sed 's/\[✓\] //')
        echo -e "${CYAN}$count)${NC} ${GREEN}✓${NC} $task_text"
    done < "$COMPLETED_FILE"
    
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "$(echo -e ${CYAN}Press Enter to continue...${NC})"
}

# Function to clear completed tasks
clear_completed() {
    show_header
    read -p "$(echo -e ${YELLOW}Are you sure? This cannot be undone (y/n):${NC}) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        > "$COMPLETED_FILE"
        echo -e "${GREEN}✓ All completed tasks cleared!${NC}"
    else
        echo -e "${YELLOW}Cancelled.${NC}"
    fi
    sleep 2
}

# Function to show statistics
show_stats() {
    show_header
    
    local pending=$(wc -l < "$TODO_FILE" 2>/dev/null || echo "0")
    local completed=$(wc -l < "$COMPLETED_FILE" 2>/dev/null || echo "0")
    local total=$((pending + completed))
    
    if [ "$total" -eq 0 ]; then
        echo -e "${YELLOW}No tasks created yet!${NC}"
        sleep 2
        return
    fi
    
    local completion_rate=0
    if [ "$total" -gt 0 ]; then
        completion_rate=$(( (completed * 100) / total ))
    fi
    
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}           ${MAGENTA}TASK STATISTICS${NC}${CYAN}          ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Total Tasks:        ${YELLOW}$total${NC}${CYAN}                     ║${NC}"
    echo -e "${CYAN}║${NC} Pending Tasks:      ${YELLOW}$pending${NC}${CYAN}                     ║${NC}"
    echo -e "${CYAN}║${NC} Completed Tasks:    ${GREEN}$completed${NC}${CYAN}                    ║${NC}"
    echo -e "${CYAN}║${NC} Completion Rate:    ${GREEN}$completion_rate%${NC}${CYAN}                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    
    # Simple progress bar
    local bar_length=30
    local filled=$((completion_rate * bar_length / 100))
    echo -e "\n${CYAN}Progress:${NC} ["
    printf "${GREEN}"
    for ((i=0; i<filled; i++)); do printf "█"; done
    printf "${NC}"
    for ((i=filled; i<bar_length; i++)); do printf "░"; done
    printf "]\n"
    
    read -p "$(echo -e ${CYAN}Press Enter to continue...${NC})"
}

# Main loop
while true; do
    show_header
    show_menu
    
    read -p "$(echo -e ${CYAN}Enter your choice (1-8):${NC}) " choice
    
    case $choice in
        1) add_task ;;
        2) view_tasks ;;
        3) mark_complete ;;
        4) delete_task ;;
        5) view_completed ;;
        6) clear_completed ;;
        7) show_stats ;;
        8) 
            echo -e "${GREEN}Goodbye! Keep being productive! 🚀${NC}\n"
            exit 0
            ;;
        *)
            echo -e "${RED}✗ Invalid choice! Please select 1-8.${NC}"
            sleep 2
            ;;
    esac
done
