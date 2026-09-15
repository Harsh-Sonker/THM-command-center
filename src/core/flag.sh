#!/usr/bin/env bash
# thm flag - Flag management

set -Eeuo pipefail

room_name=$(get_current_room)
if [[ -z "$room_name" ]]; then
    log_err "No active room."
    exit 1
fi

cmd="${1:-list}"
if [[ $# -gt 0 ]]; then shift; fi

case "$cmd" in
    set)
        type="${1:-}"
        value="${2:-}"
        if [[ -z "$type" || -z "$value" ]]; then
            log_err "Usage: thm flag set <type> <value>"
            exit 1
        fi
        
        # Save flag to DB
        run_db flag_set "$room_name" "$type" "$value" > /dev/null
        
        # Save flag to filesystem backup (encrypted or restricted)
        flag_file="$(get_room_dir "$room_name")/flags/${type}.txt"
        echo "$value" > "$flag_file"
        chmod 600 "$flag_file"
        
        log_info "Flag '$type' saved."
        ;;
        
    list)
        flags_json=$(run_db flag_list "$room_name" 2>/dev/null || echo "[]")
        
        echo -e "${BOLD}TYPE            STATUS       FOUND AT${NC}"
        echo "--------------------------------------------------------"
        
        python3 -c "
import sys, json
try:
    flags = json.loads(sys.argv[1])
    # Track expected flags
    found_types = {f['type']: f for f in flags}
    
    for expected in ['user', 'root']:
        if expected in found_types:
            f = found_types[expected]
            date = f.get('found_at', '').split('.')[0]
            print(f'{expected.ljust(15)} \033[0;32mFOUND\033[0m        {date}')
        else:
            print(f'{expected.ljust(15)} \033[0;31mMISSING\033[0m')
            
    # Print custom flags
    for t, f in found_types.items():
        if t not in ['user', 'root']:
            date = f.get('found_at', '').split('.')[0]
            print(f'{t.ljust(15)} \033[0;32mFOUND\033[0m        {date}')
except Exception as e:
    pass
" "$flags_json"
        ;;
        
    show)
        flags_json=$(run_db flag_list "$room_name" 2>/dev/null || echo "[]")
        
        echo -e "${BOLD}TYPE            VALUE${NC}"
        echo "--------------------------------------------------------"
        
        python3 -c "
import sys, json
try:
    flags = json.loads(sys.argv[1])
    for f in flags:
        print(f\"{f['type'].ljust(15)} {f['value']}\")
except Exception as e:
    pass
" "$flags_json"
        ;;
        
    *)
        log_err "Unknown flag command: $cmd"
        exit 1
        ;;
esac
