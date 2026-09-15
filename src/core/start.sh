#!/usr/bin/env bash
# thm start - Quick start workflow

set -Eeuo pipefail

if [[ $# -lt 2 ]]; then
    log_err "Usage: thm start <room_name> <target_ip>"
    exit 1
fi

room_name="$1"
target_ip="$2"

log_info "Quick Start: $room_name ($target_ip)"

# Check if room exists
room_exists=$(run_db room_get "$room_name" 2>/dev/null || echo "")

if [[ -z "$room_exists" ]]; then
    bash "${THM_CORE}/room.sh" create "$room_name"
else
    log_info "Room '$room_name' exists. Switching context..."
    set_context "$room_name" ""
fi

# Add target
bash "${THM_CORE}/target.sh" add "$target_ip"

echo ""
bash "${THM_CORE}/status.sh"

echo ""
echo -e "${YELLOW}Suggested commands:${NC}"
echo "  thm nmap quick     - Quick Nmap scan"
echo "  thm gb dir -u http://$target_ip - Directory brute-forcing"
echo "  thm run curl -i http://$target_ip/  - Capture initial request"
