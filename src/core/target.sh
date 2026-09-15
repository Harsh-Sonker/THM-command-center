#!/usr/bin/env bash
# thm target - Target management

set -Eeuo pipefail

source "${THM_CORE}/utils.sh"

cmd="${1:-list}"
if [[ "$cmd" != "" && "$cmd" != "add" && "$cmd" != "list" && "$cmd" != "use" && "$cmd" != "current" && "$cmd" != "remove" ]]; then
    # Maybe the user typed 'thm target 10.10.10.10' expecting 'use/add' behavior
    target_ip="$cmd"
    
    # Check if target exists
    room_name=$(get_current_room)
    if [[ -z "$room_name" ]]; then
        log_err "No active room. Select a room first."
        exit 1
    fi
    
    # Check if IP looks somewhat valid (basic check)
    if [[ "$target_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ || "$target_ip" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        # Default behavior: switch to it, if not exist, add it
        # But we'll just implement the switch for now
        cmd="use"
    fi
else
    if [[ $# -gt 0 ]]; then
        shift
    fi
    target_ip="${1:-}"
fi

case "$cmd" in
    add)
        if [[ -z "$target_ip" ]]; then
            log_err "Usage: thm target add <ip> [name]"
            exit 1
        fi
        
        target_name="${2:-}"
        room_name=$(get_current_room)
        
        if [[ -z "$room_name" ]]; then
            log_err "No active room. Select a room first."
            exit 1
        fi
        
        log_info "Adding target ${target_ip} to room ${room_name}..."
        run_db target_create "$room_name" "$target_ip" "$target_name" > /dev/null
        log_info "Target added."
        
        # Switch to it automatically
        set_context "$room_name" "$target_ip"
        log_info "Current target set to: $target_ip"
        ;;
        
    use)
        if [[ -z "$target_ip" ]]; then
            log_err "Usage: thm target use <ip>"
            exit 1
        fi
        
        room_name=$(get_current_room)
        if [[ -z "$room_name" ]]; then
            log_err "No active room. Select a room first."
            exit 1
        fi
        
        # In a full implementation, we'd check if the target actually belongs to the room in DB
        # For simplicity here, we assume it's valid if we switch context
        set_context "$room_name" "$target_ip"
        log_info "Switched to target: $target_ip"
        ;;
        
    current)
        curr=$(get_current_target)
        if [[ -n "$curr" ]]; then
            echo "$curr"
        else
            echo "No active target."
            exit 1
        fi
        ;;
        
    list)
        room_name=$(get_current_room)
        if [[ -z "$room_name" ]]; then
            log_err "No active room."
            exit 1
        fi
        
        targets_json=$(run_db target_list "$room_name" 2>/dev/null || echo "[]")
        
        echo -e "${BOLD}TARGET IP            NAME                 CREATED${NC}"
        echo "--------------------------------------------------------"
        
        python3 -c "
import sys, json
try:
    targets = json.loads(sys.argv[1])
    for t in targets:
        ip = t.get('ip', '').ljust(20)
        name = (t.get('name') or '').ljust(20)
        created = t.get('created_at', '').split(' ')[0]
        print(f'{ip} {name} {created}')
except Exception as e:
    pass
" "$targets_json"
        ;;
        
    *)
        log_err "Unknown target command: $cmd"
        exit 1
        ;;
esac
