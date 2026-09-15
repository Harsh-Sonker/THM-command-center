#!/usr/bin/env bash
# thm store - Universal file stashing for room directories

source "${THM_CORE}/utils.sh"

set -Eeuo pipefail

folder_type="${1:-}"
action="${2:-list}"
file="${3:-}"

room_name=$(get_current_room)
if [[ -z "$room_name" ]]; then
    log_err "No active room."
    exit 1
fi

room_dir=$(get_room_dir "$room_name")

# Map command names to actual folder paths
case "$folder_type" in
    exploit) target_dir="${room_dir}/exploits" ;;
    download) target_dir="${room_dir}/downloads" ;;
    enum) target_dir="${room_dir}/enumeration" ;;
    payload) target_dir="${room_dir}/exploits" ;;
    tmp) target_dir="${room_dir}/tmp" ;;
    *) 
        log_err "Unknown folder type: $folder_type"
        exit 1
        ;;
esac

case "$action" in
    add)
        if [[ -z "$file" ]]; then
            log_err "Usage: thm $folder_type add <file_or_text> [filename]"
            exit 1
        fi
        
        mkdir -p "$target_dir"
        
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
            if [[ -n "${4:-}" ]]; then
                filename="$4"
            fi
            dest="${target_dir}/${filename}"
            cp "$file" "$dest"
            log_info "Copied $filename to $target_dir"
        else
            filename="${4:-text_$(date +%s).txt}"
            dest="${target_dir}/${filename}"
            echo "$file" > "$dest"
            log_info "Saved text/link to $target_dir/$filename"
        fi
        ;;
        
    list)
        echo -e "${BOLD}${folder_type^^} FILES${NC}"
        echo "--------------------------------------------------------"
        if [[ -d "$target_dir" ]]; then
            ls -lh "$target_dir" | awk 'NR>1 {print $5 "\t" $9}'
        else
            echo "No files collected yet."
        fi
        ;;
        
    *)
        log_err "Unknown action: $action. Use 'add' or 'list'."
        exit 1
        ;;
esac
