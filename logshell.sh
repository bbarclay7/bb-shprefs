#!/bin/bash

# Enhanced shell command logging with timing and filtering
# Replaces record_permanent_history with added duration tracking
# Usage: source logshell.sh (typically from ~/.profile)

# Variables to track command execution
__LOGSHELL_START_TIME=""
__LOGSHELL_LAST_CMD=""
__LOGSHELL_AT_PROMPT=1  # Flag to track if we're at the prompt level

# Function called before each command (via DEBUG trap)
__logshell_preexec() {
    local cmd="$BASH_COMMAND"

    # Skip our own internal commands and setup
    [[ "$cmd" == "__logshell_"* ]] && return 0
    [[ "$cmd" == "PROMPT_COMMAND="* ]] && return 0
    [[ "$cmd" == "PS1="* ]] && return 0
    [[ "$cmd" == "trap "* ]] && return 0

    # Only capture commands at the prompt level (not inside scripts/functions)
    if [ "$__LOGSHELL_AT_PROMPT" = "1" ]; then
        __LOGSHELL_LAST_CMD="$cmd"
        __LOGSHELL_START_TIME=$(date +%s.%N)
        __LOGSHELL_AT_PROMPT=0  # No longer at prompt until next PROMPT_COMMAND
    fi
}

# Function called after each command (via PROMPT_COMMAND)
# Uses same format as original record_permanent_history but adds duration
__logshell_precmd() {
    local exit_code=$?

    # Log the command if we have one
    if [ -n "$__LOGSHELL_LAST_CMD" ] && [ -n "$__LOGSHELL_START_TIME" ]; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $__LOGSHELL_START_TIME" | bc)

        # Log using existing format: DATE|^|USER|^|HOSTNAME|^|PID|^|PPID|^|PWD|^|EXIT_CODE|^|DURATION|^|COMMAND
        # Note: macOS date doesn't support %N, so we use gdate if available, otherwise use %s
        local timestamp
        if command -v gdate &> /dev/null; then
            timestamp=$(gdate +%FT%T.%3N)
        else
            timestamp=$(date +%FT%T)
        fi
        printf "${timestamp}|^|$USER|^|$HOSTNAME|^|$$|^|$PPID|^|$PWD|^|${exit_code}|^|${duration}|^|$__LOGSHELL_LAST_CMD\n" >> ~/.bash_history_permanent

        # Clear for next command
        __LOGSHELL_LAST_CMD=""
        __LOGSHELL_START_TIME=""
    fi

    # Mark that we're back at the prompt
    __LOGSHELL_AT_PROMPT=1
}

# Function to generate git-aware prompt
__logshell_git_prompt() {
    local pwd_display=""
    local git_info=""

    # Get current directory
    local current_dir="$PWD"

    # Replace home with ~
    current_dir="${current_dir/#$HOME/\~}"

    # Check if we're in a git repo
    local git_root=$(git rev-parse --show-toplevel 2>/dev/null)

    if [ -n "$git_root" ]; then
        # We're in a git repo
        local git_branch=$(git branch --show-current 2>/dev/null || echo "detached")

        # Get the repo root relative to home
        local repo_root="${git_root/#$HOME/\~}"

        # Get the path from repo root to current directory
        local rel_path="${PWD#$git_root}"

        # Color the repo root differently from the rest of the path
        # Repo root in bright cyan, rest in bright yellow
        if [ -z "$rel_path" ]; then
            # We're at the repo root
            pwd_display="\[\033[1;36m\]${repo_root}\[\033[0m\]"
        else
            pwd_display="\[\033[1;36m\]${repo_root}\[\033[1;33m\]${rel_path}\[\033[0m\]"
        fi

        # Check if repo is dirty
        if ! git diff-index --quiet HEAD 2>/dev/null; then
            # Dirty - show branch in red with asterisk
            git_info=" \[\033[1;31m\](${git_branch}*)\[\033[0m\]"
        else
            # Clean - show branch in green
            git_info=" \[\033[1;32m\](${git_branch})\[\033[0m\]"
        fi
    else
        # Not in a git repo, color path in bright yellow
        pwd_display="\[\033[1;33m\]${current_dir}\[\033[0m\]"
    fi

    # Build the full prompt with colored user@host
    # user in green, @ in white, host in magenta, : in white, path colored, $ in white
    PS1="\[\033[0;32m\]\u\[\033[0m\]@\[\033[0;35m\]\h\[\033[0m\]:${pwd_display}${git_info}\$ "
}

# Only set up in interactive terminal
if [ -t 0 ]; then
    # Set up the traps
    trap '__logshell_preexec' DEBUG

    # Update PROMPT_COMMAND to include both logging and git prompt
    PROMPT_COMMAND='__logshell_precmd; __logshell_git_prompt'

    # Initialize state ready for the first interactive command
    __LOGSHELL_LAST_CMD=""
    __LOGSHELL_START_TIME=""
    __LOGSHELL_AT_PROMPT=1

    # Interactive helpers for hh command
    # These require fzf: brew install fzf

    # Interactive command picker - select a command and execute it
    hhi() {
        local cmd
        cmd=$(hh -i "$@")
        if [ -n "$cmd" ]; then
            # Echo the command so user can see what's being executed
            echo "$cmd"
            # Execute the command
            eval "$cmd"
        fi
    }

    # Interactive directory picker - select a directory and cd to it
    hhd() {
        local dir
        dir=$(hh -d "$@")
        if [ -n "$dir" ]; then
            # Change to the selected directory
            builtin cd "$dir" || echo "Failed to cd to: $dir" >&2
        fi
    }
fi
