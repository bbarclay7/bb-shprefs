#!/bin/bash

# Robust shell command logging with timing and execution details
# Usage: source logshell.sh [regex_pattern]
# If regex_pattern is provided, only commands matching it will be logged

# Function to log commands with all requested information
log_shell_command() {
    local cmd="$BASH_COMMAND"
    local exit_code=$?
    local start_time=$PREV_CMD_START
    local end_time=$(date +%s.%N)
    
    # Calculate duration
    local duration=$(echo "$end_time - $start_time" | bc)
    
    # Get current working directory (robust handling)
    local pwd=$(pwd)
    
    # Get hostname
    local hostname=$(hostname)
    
    # Get username
    local username=$(whoami)
    
    # Apply regex filter if provided
    if [[ -n "$REGEX_FILTER" ]] && ! [[ "$cmd" =~ $REGEX_FILTER ]]; then
        return  # Skip logging if command doesn't match filter
    fi
    
    # Log to file with robust formatting
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $username@$hostname | $pwd | $cmd | duration: ${duration}s | exit_code: $exit_code" >> ~/.shell_history.log
}

# Set up the trap to capture command execution time
PREV_CMD_START=$(date +%s.%N)
trap 'log_shell_command' DEBUG

# Set up the prompt to capture start time before each command
PS1='\$(PREV_CMD_START=$(date +%s.%N); echo -ne "\u@\h:\w\$ ")'

# Check if regex filter is provided as argument
if [[ $# -gt 0 ]]; then
    REGEX_FILTER="$1"
    echo "Shell command logging initialized with regex filter: $REGEX_FILTER"
else
    echo "Shell command logging initialized (no regex filter)"
fi

echo "Commands will be logged to ~/.shell_history.log"
echo "To use this, source this script in your shell:"
echo "  source logshell.sh [regex_pattern]"
echo "Example:"
echo "  source logshell.sh 'git.*push'"
