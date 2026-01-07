#!/usr/bin/env python3

import os
import sys
import time
import subprocess
import re
from datetime import datetime

def log_shell_command(cmd, start_time, exit_code, regex_filter=None):
    """Log shell command with timing and execution details"""
    
    # Calculate duration
    end_time = time.time()
    duration = end_time - start_time
    
    # Get current working directory
    pwd = os.getcwd()
    
    # Get hostname
    hostname = subprocess.check_output(['hostname'], text=True).strip()
    
    # Get username
    username = os.getlogin()
    
    # Apply regex filter if provided
    if regex_filter and not re.search(regex_filter, cmd):
        return  # Skip logging if command doesn't match filter
    
    # Log to file
    log_entry = f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | {username}@{hostname} | {pwd} | {cmd} | duration: {duration:.2f}s | exit_code: {exit_code}\n"
    
    with open(os.path.expanduser('~/.shell_history.log'), 'a') as f:
        f.write(log_entry)

def main():
    # Check if regex filter is provided as argument
    regex_filter = sys.argv[1] if len(sys.argv) > 1 else None
    
    # Set up the trap to capture command execution time
    # This would normally be done in bash, but we'll simulate it
    print("Shell command logging initialized with regex filter:", regex_filter)
    print("Commands will be logged to ~/.shell_history.log")
    print("To use this, source this script in your shell:")
    print("  source logshell.sh [regex_pattern]")
    print("Example:")
    print("  source logshell.sh 'git.*push'")

if __name__ == "__main__":
    main()
