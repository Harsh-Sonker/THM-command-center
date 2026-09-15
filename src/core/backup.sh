#!/usr/bin/env bash
# thm backup - Global database backup

set -Eeuo pipefail

source "${THM_CORE}/utils.sh"

backup_dir="${HOME}/.local/share/thm/backups"
mkdir -p "$backup_dir"

timestamp=$(date +"%Y%m%d_%H%M%S")
backup_db="${backup_dir}/thm_db_${timestamp}.sqlite3"

log_info "Creating database backup..."
sqlite3 "${HOME}/.local/share/thm/thm.db" ".backup '${backup_db}'"

if [[ -f "$backup_db" ]]; then
    log_info "Backup created successfully: $backup_db"
else
    log_err "Failed to create backup."
    exit 1
fi
