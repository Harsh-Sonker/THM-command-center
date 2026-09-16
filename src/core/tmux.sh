#!/usr/bin/env bash
# thm tmux - Tmux integration

set -Eeuo pipefail

source "${THM_CORE}/utils.sh"

room_name=$(get_current_room)
if [[ -z "$room_name" ]]; then
    log_err "No active room."
    exit 1
fi

if ! command -v tmux >/dev/null 2>&1; then
    log_err "Tmux is not installed."
    exit 1
fi

session_name="thm-${room_name}"

# Check if session exists
if tmux has-session -t "$session_name" 2>/dev/null; then
    log_info "Attaching to existing session: $session_name"
    tmux attach-session -t "$session_name"
    exit 0
fi

log_info "Creating new Tmux session for $room_name..."

# Create session in background
tmux new-session -d -s "$session_name" -n "Main"

# Setup layout
# ┌─────────────────────┬─────────────────────┐
# │                     │                     │
# │     Main Shell      │     Enumeration     │
# │                     │                     │
# ├─────────────────────┼─────────────────────┤
# │                     │                     │
# │     Exploitation    │      Notes          │
# │                     │                     │
# └─────────────────────┴─────────────────────┘

# Split horizontal
tmux split-window -h -t "${session_name}:0"

# Split both vertical
tmux split-window -v -t "${session_name}:0.0"
tmux split-window -v -t "${session_name}:0.2"

# Name panes if possible, or just send a clear command
tmux send-keys -t "${session_name}:0.0" "clear; echo -e '\033[1;32m=== Main Shell ===\033[0m'" C-m
tmux send-keys -t "${session_name}:0.1" "clear; echo -e '\033[1;33m=== Exploitation ===\033[0m'" C-m
tmux send-keys -t "${session_name}:0.2" "clear; echo -e '\033[1;34m=== Enumeration ===\033[0m'; echo ''; thm s --short" C-m
tmux send-keys -t "${session_name}:0.3" "clear; echo -e '\033[1;36m=== Notes ===\033[0m'; thm note" C-m

# Select top-left pane
tmux select-pane -t "${session_name}:0.0"

# Attach
tmux attach-session -t "$session_name"
