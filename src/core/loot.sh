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
        if [[ -z "$file" ]]; then
            log_err "Usage: thm loot add <file_or_text> [filename]"
            exit 1
        fi
        
        mkdir -p "$loot_dir"
        
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
            if [[ -n "${2:-}" ]]; then
                filename="$2"
            fi
            dest="${loot_dir}/${filename}"
            cp "$file" "$dest"
            log_info "Copied $filename to loot."
        else
            filename="${2:-text_$(date +%s).txt}"
            dest="${loot_dir}/${filename}"
            echo "$file" > "$dest"
            log_info "Saved text/link to loot/$filename"
        fi
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
