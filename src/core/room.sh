#!/usr/bin/env bash
# thm room - Room management

set -Eeuo pipefail

source "${THM_CORE}/utils.sh"

cmd="${1:-list}"
if [[ "$cmd" == "ls" ]]; then
    cmd="list"
fi

if [[ "$cmd" != "" && "$cmd" != "add" && "$cmd" != "create" && "$cmd" != "list" && "$cmd" != "use" && "$cmd" != "current" && "$cmd" != "finish" && "$cmd" != "solve" && "$cmd" != "end" && "$cmd" != "activate" && "$cmd" != "resume" ]]; then
    # Maybe the user typed 'thm room Overpass' expecting it to act as 'use'
    room_name="$cmd"
    cmd="use"
else
    if [[ $# -gt 0 ]]; then
        shift
    fi
    room_name="${1:-}"
fi

case "$cmd" in
    add|create)
        if [[ -z "$room_name" ]]; then
            log_err "Usage: thm room create <name>"
            exit 1
        fi
        
        # Sanitize room name (alphanumeric, dash, underscore)
        if [[ ! "$room_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            log_err "Invalid room name. Use only letters, numbers, hyphens, and underscores."
            exit 1
        fi
        
        ws=$(get_workspace)
        room_dir="${ws}/${room_name}"
        
        log_info "Creating room: $room_name"
        
        # DB insert
        run_db room_create "$room_name" "$room_dir" > /dev/null
        
        # Create directories
        mkdir -p "${room_dir}/"{targets,scans/{nmap,gobuster,ffuf,web,vuln},enumeration,exploits,findings,flags,loot,credentials,screenshots,notes,commands,sessions,downloads,reports,tmp}
        
        # Create basic README
        echo "# ${room_name}" > "${room_dir}/README.md"
        echo "Created at: $(date)" >> "${room_dir}/README.md"
        
        log_info "Room directories created."
        
        # Automatically use it
        set_context "$room_name" ""
        log_info "Switched to room: $room_name"
        ;;
        
    use)
        if [[ -z "$room_name" ]]; then
            log_err "Usage: thm room use <name>"
            exit 1
        fi
        
        # Check if room exists in DB
        room_json=$(run_db room_get "$room_name" 2>/dev/null || echo "")
        if [[ -z "$room_json" ]]; then
            log_err "Room '$room_name' not found."
            exit 1
        fi
        
        status=$(echo "$room_json" | jq -r '.status' 2>/dev/null || python3 -c "import sys, json; print(json.loads(sys.argv[1]).get('status', 'active'))" "$room_json")
        if [[ "$status" == "completed" || "$status" == "inactive" ]]; then
            log_err "Room '$room_name' is completed/inactive."
            log_err "Run 'thm room activate $room_name' to resume working on it."
            exit 1
        fi
        
        set_context "$room_name" ""
        log_info "Switched to room: $room_name"
        ;;
        
    finish|solve|end)
        if [[ -z "$room_name" ]]; then
            room_name=$(get_current_room)
        fi
        if [[ -z "$room_name" ]]; then
            log_err "No active room to finish."
            exit 1
        fi
        
        run_db room_update_status "$room_name" "completed" > /dev/null
        log_info "Room '$room_name' marked as COMPLETED! 🎉"
        ;;
        
    activate|resume)
        if [[ -z "$room_name" ]]; then
            log_err "Usage: thm room activate <name>"
            exit 1
        fi
        
        run_db room_update_status "$room_name" "active" > /dev/null
        log_info "Room '$room_name' is now ACTIVE."
        set_context "$room_name" ""
        log_info "Switched to room: $room_name"
        ;;
        
    current)
        curr=$(get_current_room)
        if [[ -n "$curr" ]]; then
            echo "$curr"
        else
            echo "No active room."
            exit 1
        fi
        ;;
        
    list)
        rooms_json=$(run_db room_list 2>/dev/null || echo "[]")
        
        # Use jq to format output nicely if possible, or basic python fallback
        echo -e "${BOLD}ROOM                 STATUS       CREATED${NC}"
        echo "--------------------------------------------------------"
        
        python3 -c "
import sys, json
try:
    rooms = json.loads(sys.argv[1])
    for r in rooms:
        name = r.get('name', '').ljust(20)
        status = r.get('status', '').upper().ljust(12)
        created = r.get('created_at', '').split(' ')[0]
        print(f'{name} {status} {created}')
except Exception as e:
    pass
" "$rooms_json"
        ;;
        
    *)
        log_err "Unknown room command: $cmd"
        exit 1
        ;;
esac
