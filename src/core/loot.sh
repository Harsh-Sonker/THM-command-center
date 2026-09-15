#!/usr/bin/env bash
# thm loot - Loot management

set -Eeuo pipefail

source "${THM_CORE}/utils.sh"

room_name=$(get_current_room)
if [[ -z "$room_name" ]]; then
    log_err "No active room."
    exit 1
fi

cmd="${1:-list}"
if [[ $# -gt 0 ]]; then shift; fi

room_dir=$(get_room_dir "$room_name")
loot_dir="${room_dir}/loot"

case "$cmd" in
    add)
        file="${1:-}"
        if [[ -z "$file" || ! -f "$file" ]]; then
            log_err "Usage: thm loot add <file>"
            exit 1
        fi
        
        filename=$(basename "$file")
        dest="${loot_dir}/${filename}"
        
        cp "$file" "$dest"
        log_info "Copied $filename to loot."
        ;;
        
    list)
        echo -e "${BOLD}LOOT FILES${NC}"
        echo "--------------------------------------------------------"
        if [[ -d "$loot_dir" ]]; then
            ls -lh "$loot_dir" | awk 'NR>1 {print $5 "\t" $9}'
        else
            echo "No loot collected yet."
        fi
        ;;
        
    *)
        log_err "Unknown loot command: $cmd"
        exit 1
        ;;
esac
