#!/usr/bin/env bash
# thm timeline - Chronological activity

set -Eeuo pipefail

room_name=$(get_current_room)
if [[ -z "$room_name" ]]; then
    log_err "No active room."
    exit 1
fi

timeline_json=$(run_db timeline "$room_name" 2>/dev/null || echo "[]")

echo -e "${BOLD}ROOM TIMELINE: $room_name${NC}"
echo "--------------------------------------------------------------------------------"

python3 -c "
import sys, json
try:
    events = json.loads(sys.argv[1])
    for e in events:
        t = e.get('type', '').ljust(12)
        date = e.get('timestamp', '').split('.')[0].ljust(20)
        detail = e.get('details', '').replace('\n', ' ')
        
        # Color code type
        if 'Command' in t: t = f'\033[0;34m{t}\033[0m'
        elif 'Finding' in t: t = f'\033[0;31m{t}\033[0m'
        elif 'Note' in t: t = f'\033[0;33m{t}\033[0m'
        elif 'Target' in t: t = f'\033[0;32m{t}\033[0m'
        elif 'Flag' in t: t = f'\033[0;35m{t}\033[0m'
        
        print(f'{date} | {t} | {detail}')
        
    if not events:
        print('No events recorded.')
except Exception as e:
    pass
" "$timeline_json"
