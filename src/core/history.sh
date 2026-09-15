#!/usr/bin/env bash
# thm history - Command history

set -Eeuo pipefail

room_name=$(get_current_room)
if [[ -z "$room_name" ]]; then
    log_err "No active room."
    exit 1
fi

tool_filter=""
if [[ "${1:-}" == "--tool" && -n "${2:-}" ]]; then
    tool_filter="$2"
fi

history_json=$(run_db command_list "$room_name" "$tool_filter" 2>/dev/null || echo "[]")

echo -e "${BOLD}ID   TOOL         EXIT  DATE                 COMMAND${NC}"
echo "--------------------------------------------------------------------------------"

python3 -c "
import sys, json
try:
    history = json.loads(sys.argv[1])
    for cmd in history[:50]: # limit to 50 for now
        id_str = str(cmd.get('id', '')).ljust(4)
        tool = cmd.get('tool', '').ljust(12)
        exit_code = str(cmd.get('exit_code', '')).ljust(4)
        date = cmd.get('executed_at', '').split('.')[0].ljust(20) # basic strip
        full = cmd.get('full_command', '')
        if len(full) > 40:
            full = full[:37] + '...'
        
        # Color exit code red if not 0
        if exit_code.strip() != '0':
            exit_code = f'\033[0;31m{exit_code}\033[0m'
            
        print(f'{id_str} {tool} {exit_code} {date} {full}')
except Exception as e:
    pass
" "$history_json"
