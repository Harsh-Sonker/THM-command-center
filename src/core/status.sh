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

echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              THM COMMAND CENTER          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Current Room${NC} : $room"
echo -e "${BOLD}Target${NC}       : ${target:-None}"

# Later, this script will query the database to show
# Ports, Findings, Commands, Evidence, Flags, etc.
# For now, it's a stub that shows the context.

# Example placeholder for future DB queries
echo -e "${BOLD}Status${NC}       : ACTIVE (placeholder)"
echo ""
echo -e "${BOLD}TODO${NC}"
echo "─────────────────────────────────────────"
echo " (No tasks added yet)"
echo ""
echo -e "${BOLD}Recent Activity${NC}"
echo "─────────────────────────────────────────"
echo " (No recent activity recorded)"
