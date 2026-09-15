#!/usr/bin/env bash
# thm - Core utilities

# Colors
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    NC=''
fi

# Logging functions
log_info() {
    echo -e "${GREEN}[+]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1" >&2
}

log_err() {
    echo -e "${RED}[x]${NC} $1" >&2
}

log_fatal() {
    echo -e "${RED}[x] FATAL:${NC} $1" >&2
    exit 1
}

# Python DB runner helper
run_db() {
    local db_script="${THM_CORE}/db.py"
    if [[ ! -f "$db_script" ]]; then
        log_fatal "Database script not found at ${db_script}"
    fi
    python3 "$db_script" "$@"
}

# Context retrieval helpers
get_current_room() {
    local ctx_file="${THM_CONFIG_DIR}/.ctx"
    if [[ -f "$ctx_file" ]]; then
        local room=$(grep "^ROOM=" "$ctx_file" | cut -d= -f2-)
        if [[ -n "$room" ]]; then
            echo "$room"
            return 0
        fi
    fi
    echo ""
    return 1
}

get_current_target() {
    local ctx_file="${THM_CONFIG_DIR}/.ctx"
    if [[ -f "$ctx_file" ]]; then
        local target=$(grep "^TARGET=" "$ctx_file" | cut -d= -f2-)
        if [[ -n "$target" ]]; then
            echo "$target"
            return 0
        fi
    fi
    echo ""
    return 1
}

set_context() {
    local room="$1"
    local target="${2:-}"
    
    mkdir -p "${THM_CONFIG_DIR}"
    local ctx_file="${THM_CONFIG_DIR}/.ctx"
    
    # Check if we're only updating target
    if [[ -z "$room" && -f "$ctx_file" ]]; then
        room=$(get_current_room)
    fi
    
    echo "ROOM=${room}" > "$ctx_file"
    echo "TARGET=${target}" >> "$ctx_file"
}

clear_context() {
    local ctx_file="${THM_CONFIG_DIR}/.ctx"
    > "$ctx_file"
}

# Workspace helper
get_workspace() {
    # Default to ~/TryHackMe unless overridden in config
    # TODO: Read from config.conf
    echo "${HOME}/TryHackMe"
}

get_room_dir() {
    local room="$1"
    local ws=$(get_workspace)
    echo "${ws}/${room}"
}
