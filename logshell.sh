#!/bin/bash

# Command logging function
log_shell_command() {
    local cmd="$BASH_COMMAND"
    local exit_code=$?
    local start_time=$PREV_CMD_START
    local end_time=$(date +%s.%N)
    
    # Calculate duration
    local duration=$(echo "$end_time - $start_time" | bc)
    
    # Get current working directory
    local pwd=$(pwd)
    
    # Get hostname
    local hostname=$(hostname)
    
    # Get username
    local username=$(whoami)
    
    # Log to file
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $username@$hostname | $pwd | $cmd | duration: ${duration}s | exit_code: $exit_code" >> ~/.shell_history.log
}

# Set up the trap to capture command execution time
PREV_CMD_START=$(date +%s.%N)
trap 'log_shell_command' DEBUG

# Set up the prompt to capture start time before each command
PS1='\$(PREV_CMD_START=$(date +%s.%N); echo -ne "\u@\h:\w\$ ")'
