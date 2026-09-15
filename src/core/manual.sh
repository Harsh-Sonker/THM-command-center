#!/usr/bin/env bash
# thm manual - Built-in command reference

source "${THM_CORE}/utils.sh"

set -Eeuo pipefail

log_info "THM Command Center - Interactive Manual"
echo "================================================================"

cat << 'EOF'
1. Core Commands
----------------------------------------------------------------
thm start <room> <ip>    : Create a room, set target, & switch context
thm status (or s)        : Show current room and target IP
thm ctx                  : Print context quietly
thm jump (or enter)      : Open a new shell inside the room's directory
thm tmux                 : Launch a 4-pane Tmux hacking dashboard
thm init                 : Initialize database (run once after install)

2. Target & Room Management
----------------------------------------------------------------
thm room ls              : List all rooms
thm room use <room>      : Switch active room
thm target add <ip>      : Add an extra IP to current room
thm target use <ip>      : Switch to another IP
thm ip <new_ip>          : Update the current target's IP address

3. Tools & Logging
----------------------------------------------------------------
thm run <cmd> (or r)     : Wrap any command to log output and timing
thm <tool> [args]        : Built-in wrappers (nmap, gobuster, ffuf, nikto, curl)
                           Example: thm nmap -sC -sV
thm history (or h)       : View command history for the room

4. Entities & Evidence
----------------------------------------------------------------
thm flag set <type> <val>: Save a flag (e.g. thm flag set user THM{...})
thm flag list            : See missing/found flags
thm flag show            : Reveal flag plaintext
thm finding add "<title>": Log a vulnerability
thm cred add <usr> <pw>  : Save a credential (passwords masked by default)
thm note add "<text>"    : Add a note (or run without text for nano editor)
thm todo add "<task>"    : Add a checklist task
thm loot add <file>      : Copy evidence into loot folder
thm screenshot add <file>: Copy image into screenshots folder
thm exploit add <file>   : Copy a file to the exploits folder
thm download add <file>  : Copy a file to the downloads folder
thm enum add <file>      : Copy a file to the enumeration folder

5. Advanced
----------------------------------------------------------------
thm search <keyword>     : Global search across all rooms/history/notes
thm timeline             : Chronological timeline of room activity
thm report               : Generate a Markdown executive summary
thm export               : Package room into a portable .tar.gz archive
thm backup               : Backup the global SQLite database
EOF
echo "================================================================"
