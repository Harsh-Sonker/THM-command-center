#!/usr/bin/env bash
# thm note - Note management

set -Eeuo pipefail

room_name=$(get_current_room)
if [[ -z "$room_name" ]]; then
    log_err "No active room."
    exit 1
fi

cmd="${1:-list}"
if [[ "$cmd" != "add" && "$cmd" != "list" && "$cmd" != "edit" ]]; then
    # Default to add if they just typed `thm note "something"`
    content="$*"
    if [[ -n "$content" ]]; then
        cmd="add"
    else
        cmd="list"
    fi
else
    if [[ $# -gt 0 ]]; then shift; fi
    content="$*"
fi

case "$cmd" in
    add)
        if [[ -z "$content" ]]; then
            # Open editor if no content provided inline
            editor="${EDITOR:-nano}"
            tmpfile=$(mktemp)
            $editor "$tmpfile"
            content=$(cat "$tmpfile")
            rm -f "$tmpfile"
            
            if [[ -z "$content" ]]; then
                log_err "Empty note. Aborted."
                exit 1
            fi
        fi
        
        run_db note_add "$room_name" "$content" > /dev/null
        log_info "Note added."
        ;;
        
    list)
        notes_json=$(run_db note_list "$room_name" 2>/dev/null || echo "[]")
        
        echo -e "${BOLD}NOTES${NC}"
        echo "--------------------------------------------------------"
        
        python3 -c "
import sys, json
try:
    notes = json.loads(sys.argv[1])
    for n in notes:
        id_str = str(n['id']).ljust(3)
        date = n.get('created_at', '').split('.')[0]
        content = n.get('content', '')
        # Truncate content for list view
        if len(content) > 50:
            content = content[:47].replace('\n', ' ') + '...'
        else:
            content = content.replace('\n', ' ')
        print(f'{id_str} [{date}] {content}')
except Exception as e:
    pass
" "$notes_json"
        ;;
        
    *)
        log_err "Unknown note command: $cmd"
        exit 1
        ;;
esac
