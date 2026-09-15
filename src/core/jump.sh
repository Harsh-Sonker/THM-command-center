#!/usr/bin/env bash
# thm jump - Spawn a shell in the active room directory

source "${THM_CORE}/utils.sh"

set -Eeuo pipefail

room_name=$(get_current_room)
if [[ -z "$room_name" ]]; then
    log_err "No active room."
    exit 1
fi

room_dir=$(get_room_dir "$room_name")

if [[ ! -d "$room_dir" ]]; then
    log_err "Room directory not found: $room_dir"
    exit 1
fi

# Check if room is active
room_json=$(run_db room_get "$room_name" 2>/dev/null || echo "")
status=$(echo "$room_json" | jq -r '.status' 2>/dev/null || python3 -c "import sys, json; print(json.loads(sys.argv[1]).get('status', 'active'))" "$room_json")

if [[ "$status" == "completed" || "$status" == "inactive" ]]; then
    log_err "Room '$room_name' is marked as COMPLETED/INACTIVE."
    log_err "Run 'thm room activate $room_name' to unlock it."
    exit 1
fi

echo -e "\033[1;32mJumping to workspace: $room_name\033[0m"
echo -e "Type '\033[1;33mexit\033[0m' to return to your previous directory."

cd "$room_dir"
exec "${SHELL:-bash}"
