#!/usr/bin/env bash
# thm init - Initialize the workspace and database

set -Eeuo pipefail

log_info "Initializing THM Command Center..."

# Create workspace
WS=$(get_workspace)
if [[ ! -d "$WS" ]]; then
    mkdir -p "$WS"
    chmod 700 "$WS"
    log_info "Created workspace: $WS"
else
    log_info "Workspace exists: $WS"
fi

# Create config directory
if [[ ! -d "$THM_CONFIG_DIR" ]]; then
    mkdir -p "$THM_CONFIG_DIR"
    chmod 700 "$THM_CONFIG_DIR"
    log_info "Created config directory: $THM_CONFIG_DIR"
fi

# Create global app directory
if [[ ! -d "${THM_DIR}/logs" ]]; then
    mkdir -p "${THM_DIR}/logs"
    chmod 700 "${THM_DIR}"
    log_info "Created application directory: ${THM_DIR}"
fi

# Initialize database
if [[ ! -f "${THM_DIR}/thm.db" ]]; then
    log_info "Initializing SQLite database..."
    run_db init
    if [[ $? -eq 0 ]]; then
        chmod 600 "${THM_DIR}/thm.db"
        log_info "Database initialized successfully."
    else
        log_err "Failed to initialize database."
        exit 1
    fi
else
    log_info "Database already exists."
fi

log_info "THM Command Center is ready!"
log_info "Run 'thm start <room> <ip>' to begin."
