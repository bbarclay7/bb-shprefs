# hh - Superpowered Shell History Utility

A powerful command-line tool for viewing, searching, and analyzing your shell command history with advanced filtering, statistics, and interactive features.

## Overview

`hh` works with the enhanced shell logging system provided by `logshell.sh`, which tracks every command you run with timing information, exit codes, working directory, and more. All history is stored in `~/.bash_history_permanent` in a pipe-delimited format.

## Basic Usage

```bash
# Show commands from current directory
hh

# Show all commands from all directories
hh -a

# Show last 10 commands
hh -n 10

# Show verbose output with duration and pwd
hh -v
```

## Filtering

### Directory Filtering
```bash
# Show commands from current directory (default)
hh

# Show all directories
hh -a

# Filter by path regex
hh -p "bb-shprefs"
hh -p "/Users/.*project"
```

### Command Filtering
```bash
# Filter by command regex
hh -r "git.*commit"
hh -r "^npm"

# Exclude commands matching pattern
hh --exclude "test"
hh --exclude "ls|cd"
```

### Time-Based Filtering
```bash
# Commands since a specific time
hh --since "2 hours ago"
hh --since "30 minutes ago"
hh --since "2026-01-07"

# Commands until a specific time
hh --until "2026-01-07"

# Quick shortcuts
hh --today
hh --yesterday
hh --thisweek
```

### Exit Code Filtering
```bash
# Show only failed commands
hh --failures

# Show commands with specific exit code
hh -e 127
hh --exitcode 0
```

### Duration Filtering
```bash
# Show only slow commands (>5 seconds)
hh --slow 5.0

# Show very slow commands (>30 seconds)
hh --slow 30
```

### Session Filtering
```bash
# Show only commands from current shell session
hh --session

# List all shell sessions
hh --sessions

# Filter by specific session ID (PPID)
hh --session-id 12345
```

## Interactive Modes

### Interactive Command Picker (hhi / Ctrl-R)
```bash
# Interactive fuzzy search and execute
hhi

# Or press Ctrl-R in your shell
# - Automatically deduplicated (newest wins)
# - Cursor starts on most recent command
# - Selected command executes immediately
# - Press Ctrl-C to cancel
```

### Interactive Directory Picker (hhd)
```bash
# Select directory from history and cd to it
hhd

# Filter to specific path pattern first
hhd -p "projects"
```

### Advanced Interactive Options
```bash
# Enable preview window showing command details
hh -i --preview

# Allow selecting multiple commands
hh -i --multiselect

# Combine with other filters
hh -i --failures --preview  # Browse failed commands with details
```

## Statistics and Analysis

### Command Statistics
```bash
# Show comprehensive stats
hh --stats

# Output includes:
# - Total and unique command counts
# - Top 10 most frequent commands
# - Success/failure distribution
# - Duration statistics (avg, median, max)
# - Slowest commands
```

### Examples
```bash
# Stats for today only
hh --today --stats

# Stats for a specific directory
hh -p "myproject" --stats

# Stats for failed commands
hh --failures --stats

# Stats for a specific session
hh --session-id 12345 --stats
```

## Export

### CSV Export
```bash
# Export to CSV file
hh --export-csv history.csv

# Export filtered results
hh --today --export-csv today.csv
hh -p "project" --export-csv project_history.csv
```

### JSON Export
```bash
# Export to JSON file
hh --export-json history.json

# Export with filters
hh --since "1 week ago" --export-json last_week.json
```

## Deduplication Control

```bash
# Default: deduplicate by full command (newest wins)
hh -i

# Deduplicate by command name only (ignore arguments)
hh -i --unique-args
# e.g., "git status" and "git commit -m foo" both count as "git"

# Disable deduplication entirely
hh -i --keep-all-dups
```

## Display Options

### Timestamp Formats
```bash
# Default: relative time (e.g., "5m ago", "2h ago")
hh

# Absolute ISO timestamp
hh --absdate
# Shows: 2026-01-07T14:30:15
```

### Output Format
```bash
# Default format: [time ec=code] command
hh

# Verbose format: includes duration and pwd
hh -v
# Shows: [time ec=code] command (duration=1.23s pwd=/path)
```

## Combining Options

All options can be combined for powerful filtering:

```bash
# Failed git commands from last hour
hh --since "1 hour ago" -r "^git" --failures

# Slow npm commands interactively
hh -r "^npm" --slow 10 -i --preview

# Today's commands in specific directory as CSV
hh --today -p "myproject" --export-csv today_work.csv

# Interactive search of yesterday's failures
hh --yesterday --failures -i
```

## Common Workflows

### Debug what failed recently
```bash
hh --failures -n 20
```

### Find that command you ran last week
```bash
hh --since "1 week ago" -i
```

### Review today's work
```bash
hh --today -v
```

### Find slow database queries
```bash
hh -r "psql|mysql" --slow 5
```

### Export project history for analysis
```bash
hh -p "myproject" --export-json project_stats.json
```

### Browse commands from a specific session
```bash
# First, find the session
hh --sessions

# Then filter to that session (using current shell)
hh --session

# Or view commands from a specific session by PPID
hh --session-id 12345

# Get stats for a specific session
hh --session-id 12345 --stats
```

## Integration with Shell

The `logshell.sh` script sets up:

- **hhi()** - Interactive command picker function
- **hhd()** - Interactive directory picker function
- **Ctrl-R** - Bound to `hhi` for instant command search

## Log Format

The history log (`~/.bash_history_permanent`) uses pipe-delimited format:

```
DATE|^|USER|^|HOSTNAME|^|PID|^|PPID|^|PWD|^|EXIT_CODE|^|DURATION|^|COMMAND
```

### Fields
- **DATE**: ISO 8601 timestamp (e.g., `2026-01-07T14:30:15.123`)
- **USER**: Username
- **HOSTNAME**: Machine hostname
- **PID**: Process ID of the shell
- **PPID**: Parent process ID (for session tracking)
- **PWD**: Working directory when command was run
- **EXIT_CODE**: Command exit code (0 = success)
- **DURATION**: Execution time in seconds (with subsecond precision)
- **COMMAND**: The actual command that was executed

## Tips

1. **Use interactive mode** (`-i` or Ctrl-R) for quick command recall
2. **Combine filters** to narrow down exactly what you need
3. **Use stats mode** (`--stats`) to understand your command usage patterns
4. **Export to JSON/CSV** for deeper analysis with other tools
5. **Filter by time** to focus on recent work or specific dates
6. **Use `--preview`** in interactive mode to see full command details
7. **Auto-filter with `-p`** to work within specific projects/directories

## Color Coding

- **Exit codes**: Green for success (0), Red for failure (non-zero)
- **Timestamps**: Either relative ("5m ago") or absolute ISO format
- **All colors**: Use standard 16-color ANSI palette for compatibility

## Notes

- Commands starting with `hh` and `bind` are automatically filtered out
- History is deduplicated by default in interactive mode (newest wins)
- All regex patterns use Python's `re` module syntax
- Time specifications support natural language ("2 hours ago") and ISO dates
- Duration is tracked with subsecond precision where available
