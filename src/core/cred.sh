#!/usr/bin/env bash
# thm cred - Credential management

set -Eeuo pipefail

source "${THM_CORE}/utils.sh"

room_name=$(get_current_room)
if [[ -z "$room_name" ]]; then
    log_err "No active room."
    exit 1
fi

cmd="${1:-list}"
if [[ $# -gt 0 ]]; then shift; fi

case "$cmd" in
    add)
        username="${1:-}"
        password="${2:-}"
        service="${3:-}"
        if [[ -z "$username" || -z "$password" ]]; then
            log_err "Usage: thm cred add <username> <password> [service]"
            exit 1
        fi
        
        run_db cred_add "$room_name" "$username" "$password" "$service" > /dev/null
        log_info "Credential added for user: $username"
        ;;
        
    list)
        creds_json=$(run_db cred_list "$room_name" 2>/dev/null || echo "[]")
        
        echo -e "${BOLD}ID  USERNAME             SERVICE${NC}"
        echo "--------------------------------------------------------"
        
        python3 -c "
import sys, json
try:
    creds = json.loads(sys.argv[1])
    for c in creds:
        id_str = str(c['id']).ljust(3)
        user = c.get('username', '').ljust(20)
        svc = c.get('service', '')
        print(f'{id_str} {user} {svc}')
except Exception as e:
    pass
" "$creds_json"
        ;;
        
    show)
        cred_id="${1:-}"
        if [[ -z "$cred_id" ]]; then
            log_err "Usage: thm cred show <id>"
            exit 1
        fi
        
        cred_json=$(run_db cred_show "$room_name" "$cred_id" 2>/dev/null || echo "")
        if [[ -z "$cred_json" ]]; then
            log_err "Credential not found."
            exit 1
        fi
        
        python3 -c "
import sys, json
try:
    c = json.loads(sys.argv[1])
    print(f\"Username : {c.get('username')}\")
    print(f\"Password : {c.get('password')}\")
    print(f\"Hash     : {c.get('hash', 'N/A')}\")
    print(f\"Service  : {c.get('service', 'N/A')}\")
except Exception as e:
    pass
" "$cred_json"
        ;;
        
    *)
        log_err "Unknown cred command: $cmd"
        exit 1
        ;;
esac
