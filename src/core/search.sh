#!/usr/bin/env bash
# thm search - Global search

set -Eeuo pipefail

keyword="${1:-}"

if [[ -z "$keyword" ]]; then
    log_err "Usage: thm search <keyword>"
    exit 1
fi

log_info "Searching for '$keyword'..."

search_json=$(run_db search "$keyword" 2>/dev/null || echo "[]")

echo -e "${BOLD}TYPE       ROOM            DATE                 DETAILS${NC}"
echo "--------------------------------------------------------------------------------"

python3 -c "
import sys, json
try:
    results = json.loads(sys.argv[1])
    for r in results:
        t = r.get('type', '').ljust(10)
        room = r.get('room', '').ljust(15)
        date = r.get('timestamp', '').split('.')[0].ljust(20)
        detail = r.get('detail', '').replace('\n', ' ')
        if len(detail) > 40:
            detail = detail[:37] + '...'
        
        # Color code type
        if 'Command' in t: t = f'\033[0;34m{t}\033[0m'
        elif 'Finding' in t: t = f'\033[0;31m{t}\033[0m'
        elif 'Note' in t: t = f'\033[0;33m{t}\033[0m'
        elif 'Target' in t: t = f'\033[0;32m{t}\033[0m'
        
        print(f'{t} {room} {date} {detail}')
    
    if not results:
        print('No results found.')
except Exception as e:
    pass
" "$search_json"
