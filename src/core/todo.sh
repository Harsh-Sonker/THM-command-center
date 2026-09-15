#!/usr/bin/env bash
# thm todo - Task management

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
        desc="${*}"
        if [[ -z "$desc" ]]; then
            log_err "Usage: thm todo add <description>"
            exit 1
        fi
        
        run_db todo_add "$room_name" "$desc" > /dev/null
        log_info "Task added."
        ;;
        
    done)
        task_id="${1:-}"
        if [[ -z "$task_id" ]]; then
            log_err "Usage: thm todo done <id>"
            exit 1
        fi
        
        run_db todo_done "$room_name" "$task_id" > /dev/null
        log_info "Task $task_id marked as completed."
        ;;
        
    list)
        todo_json=$(run_db todo_list "$room_name" 2>/dev/null || echo "[]")
        
        echo -e "${BOLD}TODO LIST${NC}"
        echo "--------------------------------------------------------"
        
        python3 -c "
import sys, json
try:
    tasks = json.loads(sys.argv[1])
    for t in tasks:
        id_str = str(t['id']).ljust(3)
        status = t.get('status', '')
        desc = t.get('description', '')
        
        if status == 'completed':
            print(f'{id_str} [\033[0;32mx\033[0m] {desc}')
        else:
            print(f'{id_str} [ ] {desc}')
except Exception as e:
    pass
" "$todo_json"
        ;;
        
    *)
        log_err "Unknown todo command: $cmd"
        exit 1
        ;;
esac
