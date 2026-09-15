#!/usr/bin/env bash
# thm doctor - Environment and dependency health check

set -Eeuo pipefail

log_info "Running THM Doctor Health Check..."
echo "--------------------------------------------------------"

check_cmd() {
    local cmd="$1"
    local required="${2:-false}"
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "[\033[0;32mOK\033[0m] $cmd"
    else
        if [[ "$required" == "true" ]]; then
            echo -e "[\033[0;31mERR\033[0m] $cmd (REQUIRED)"
        else
            echo -e "[\033[0;33mWARN\033[0m] $cmd (Optional)"
        fi
    fi
}

echo -e "${BOLD}Dependencies:${NC}"
check_cmd "bash" "true"
check_cmd "python3" "true"
check_cmd "sqlite3" "true"
check_cmd "jq" "true"
check_cmd "nmap" "false"
check_cmd "gobuster" "false"
check_cmd "ffuf" "false"
check_cmd "nikto" "false"
check_cmd "curl" "false"
check_cmd "wget" "false"
check_cmd "tmux" "false"
check_cmd "script" "false"
check_cmd "sqlmap" "false"

echo ""
echo -e "${BOLD}Application Data:${NC}"
THM_DIR="${HOME}/.local/share/thm"
if [[ -d "$THM_DIR" ]]; then
    echo -e "[\033[0;32mOK\033[0m] Application directory exists"
else
    echo -e "[\033[0;31mERR\033[0m] Application directory missing"
fi

DB_PATH="${THM_DIR}/thm.db"
if [[ -f "$DB_PATH" ]]; then
    echo -e "[\033[0;32mOK\033[0m] Database exists"
    
    # Check integrity
    integrity=$(sqlite3 "$DB_PATH" "PRAGMA integrity_check;" 2>/dev/null)
    if [[ "$integrity" == "ok" ]]; then
        echo -e "[\033[0;32mOK\033[0m] SQLite integrity check passed"
    else
        echo -e "[\033[0;31mERR\033[0m] SQLite integrity check failed!"
    fi
else
    echo -e "[\033[0;31mERR\033[0m] Database missing"
fi

echo ""
echo -e "${BOLD}Context:${NC}"
room=$(get_current_room || echo "")
if [[ -n "$room" ]]; then
    echo -e "[\033[0;32mOK\033[0m] Active room: $room"
    ws=$(get_workspace)
    if [[ -d "${ws}/${room}" ]]; then
        echo -e "[\033[0;32mOK\033[0m] Room workspace exists"
    else
        echo -e "[\033[0;31mERR\033[0m] Room workspace directory is missing!"
    fi
else
    echo -e "[\033[0;33mINFO\033[0m] No active room context"
fi

echo "--------------------------------------------------------"
log_info "Doctor check complete."
