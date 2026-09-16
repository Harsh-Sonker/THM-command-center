#!/usr/bin/env bash
# thm status - Current status dashboard

set -Eeuo pipefail

source "${THM_CORE}/utils.sh"

room=$(get_current_room)
target=$(get_current_target)

if [[ -z "$room" ]]; then
    log_err "No active room."
    exit 1
fi

short_mode=0
if [[ "${1:-}" == "--short" || "${1:-}" == "-s" ]]; then
    short_mode=1
fi

if [[ $short_mode -eq 0 ]]; then
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              THM COMMAND CENTER          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo ""
fi
echo -e "${BOLD}Current Room${NC} : $room"
echo -e "${BOLD}Target${NC}       : ${target:-None}"

room_json=$(run_db room_get "$room" 2>/dev/null || echo "")
db_status=$(echo "$room_json" | jq -r '.status' 2>/dev/null || python3 -c "import sys, json; print(json.loads(sys.argv[1]).get('status', 'ACTIVE'))" "$room_json" 2>/dev/null || echo "ACTIVE")

if [[ "${db_status^^}" == "COMPLETED" ]]; then
    color="\033[1;32m" # Green
elif [[ "${db_status^^}" == "INACTIVE" ]]; then
    color="\033[1;31m" # Red
else
    color="\033[1;36m" # Cyan
fi

echo -e "${BOLD}Status${NC}       : ${color}${db_status^^}${NC}"
echo ""
echo -e "${BOLD}TODO${NC}"
echo "─────────────────────────────────────────"
echo " (No tasks added yet)"
echo ""
echo -e "${BOLD}Recent Activity${NC}"
echo "─────────────────────────────────────────"
echo " (No recent activity recorded)"
