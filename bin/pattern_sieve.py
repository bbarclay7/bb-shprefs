#!/usr/bin/env python

import PySimpleGUI as sg
import re
import os
import sys

def load_file_content(filename):
    with open(filename, 'r') as file:
        return file.read()

def filter_and_count_content(file_content, patterns):
    lines = file_content.splitlines()
    pattern_counts = {pattern: 0 for pattern in patterns}

    filtered_content = []
    for line in lines:
        matched = False
        for pattern in patterns:
            if re.search(pattern, line):
                matched = True
                pattern_counts[pattern] += 1
                break
        if not matched:
            filtered_content.append(line)

    return '\n'.join(filtered_content), pattern_counts

def save_patterns(patterns, filename):
    with open(filename, 'w') as file:
        for pattern, _ in patterns:
            file.write(f"{pattern}\n")

def load_patterns(filename):
    with open(filename, 'r') as file:
        return [(pattern.strip(), 0) for pattern in file.readlines()]

layout = [
    [sg.Multiline(size=(40, 25), key='-FILE_CONTENT-'), 
     sg.Listbox(values=[], size=(40, 20), key='-PATTERNS-', enable_events=False, select_mode='LISTBOX_SELECT_MODE_SINGLE')],
    [sg.Text('', size=(40, 1), key='-STATS-1-'), sg.Text('', size=(40, 1), key='-STATS-2-')],
    [sg.Text(''), 
     sg.Button('Add'), sg.Button('Edit'), sg.Button('Remove'),
     sg.Button('Save'), sg.Button('Load')]
]

window = sg.Window('Regex Filter App with PySimpleGUI', layout, finalize=True)

# Accept command line arguments
if len(sys.argv) < 2:
    sg.popup_error('Usage: python script_name.py <text_filename> [pattern_filename]')
    sys.exit(1)

text_filename = sys.argv[1]
pattern_filename = sys.argv[2] if len(sys.argv) > 2 else None

file_content = load_file_content(text_filename)
patterns = load_patterns(pattern_filename) if pattern_filename else []

while True:
    filtered_content, pattern_counts = filter_and_count_content(file_content, [pattern for pattern, _ in patterns])
    total_lines = len(file_content.splitlines())
    matched_lines = sum(pattern_counts.values())
    percentage_matched = (matched_lines / total_lines) * 100 if total_lines > 0 else 0
    stats_text_1 = f"Total lines: {total_lines} | Matched: {matched_lines}"
    stats_text_2 = f"Percentage matched: {percentage_matched:.2f}%"

    patterns_display = [f"{pattern} (Matches: {pattern_counts[pattern]})" for pattern, _ in patterns]
    window['-FILE_CONTENT-'].update(filtered_content)
    window['-PATTERNS-'].update(values=patterns_display)
    window['-STATS-1-'].update(stats_text_1)
    window['-STATS-2-'].update(stats_text_2)

    event, values = window.read()

    if event == sg.WIN_CLOSED:
        break
    elif event == 'Add':
        pattern = sg.popup_get_text('Enter the regex pattern:')
        if pattern:
            patterns.append((pattern, 0))
    elif event == 'Edit':
        if values['-PATTERNS-']:
            selected_pattern_string = values['-PATTERNS-'][0]
            selected_pattern = selected_pattern_string.split(" (Matches:")[0]
            new_pattern = sg.popup_get_text('Modify the regex pattern:', default_text=selected_pattern)
            if new_pattern:
                index = next(i for i, (pat, _) in enumerate(patterns) if pat == selected_pattern)
                patterns[index] = (new_pattern, 0)
                patterns_display[index] = f"{new_pattern} (Matches: 0)"  # Update pattern in the display list immediately
                window['-PATTERNS-'].update(values=patterns_display)
    elif event == 'Remove':
        print(f"BB> REMOVE")
        if values['-PATTERNS-']:
            selected_pattern_string = values['-PATTERNS-'][0]
            print(f"BB> {selected_pattern_string=}")
            selected_pattern = selected_pattern_string.split(" (Matches:")[0]
            index = next(i for i, (pat, _) in enumerate(patterns) if pat == selected_pattern)
            del patterns[index]  # Remove pattern from patterns list
            del patterns_display[index]  # Remove pattern from display list
            window['-PATTERNS-'].update(values=patterns_display)
        else:
            print("NOPE")
    elif event == 'Save':
        filename = sg.popup_get_file('Save patterns to:', save_as=True, no_window=True)
        if filename:
            save_patterns(patterns, filename)
    elif event == 'Load':
        filename = sg.popup_get_file('Load patterns from:', no_window=True)
        if filename:
            patterns = load_patterns(filename)


window.close()
