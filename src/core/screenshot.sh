#!/usr/bin/env bash
# thm screenshot - Screenshot management

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
screenshot_dir="${room_dir}/screenshots"

case "$cmd" in
    add)
        file="${1:-}"
        if [[ -z "$file" ]]; then
            log_err "Usage: thm screenshot add <file_or_text> [filename]"
            exit 1
        fi
        
        mkdir -p "$screenshot_dir"
        
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
            if [[ -n "${2:-}" ]]; then
                filename="$2"
            fi
            dest="${screenshot_dir}/${filename}"
            cp "$file" "$dest"
            log_info "Copied $filename to screenshots."
        else
            filename="${2:-text_$(date +%s).txt}"
            dest="${screenshot_dir}/${filename}"
            echo "$file" > "$dest"
            log_info "Saved text/link to screenshots/$filename"
        fi
        ;;
        
    list)
        echo -e "${BOLD}SCREENSHOTS${NC}"
        echo "--------------------------------------------------------"
        if [[ -d "$screenshot_dir" ]]; then
            ls -lh "$screenshot_dir" | awk 'NR>1 {print $5 "\t" $9}'
        else
            echo "No screenshots collected yet."
        fi
        ;;
        
    *)
        log_err "Unknown screenshot command: $cmd"
        exit 1
        ;;
esac
