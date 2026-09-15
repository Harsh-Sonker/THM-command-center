#!/usr/bin/env bash
# thm finding - Findings management

set -Eeuo pipefail

source "${THM_CORE}/utils.sh"

room_name=$(get_current_room)
if [[ -z "$room_name" ]]; then
    log_err "No active room."
    exit 1
fi

cmd="${1:-list}"
if [[ $# -gt 0 ]]; then shift; fi

case "$cmd" in
    add)
        title="${1:-}"
        if [[ -z "$title" ]]; then
            log_err "Usage: thm finding add <title> [--severity <low|medium|high|critical>]"
            exit 1
        fi
        
        severity="medium"
        if [[ "${2:-}" == "--severity" && -n "${3:-}" ]]; then
            severity="$3"
        fi
        
        run_db finding_add "$room_name" "$title" "$severity" > /dev/null
        log_info "Finding added: $title ($severity)"
        ;;
        
    list)
        findings_json=$(run_db finding_list "$room_name" 2>/dev/null || echo "[]")
        
        echo -e "${BOLD}ID  SEVERITY     STATUS       TITLE${NC}"
        echo "--------------------------------------------------------"
        
        python3 -c "
import sys, json
try:
    findings = json.loads(sys.argv[1])
    for f in findings:
        id_str = str(f['id']).ljust(3)
        sev = f.get('severity', 'unknown').upper()
        if sev == 'CRITICAL': sev = f'\033[1;31m{sev.ljust(12)}\033[0m'
        elif sev == 'HIGH': sev = f'\033[0;31m{sev.ljust(12)}\033[0m'
        elif sev == 'MEDIUM': sev = f'\033[0;33m{sev.ljust(12)}\033[0m'
        elif sev == 'LOW': sev = f'\033[0;34m{sev.ljust(12)}\033[0m'
        else: sev = sev.ljust(12)
        
        status = f.get('status', '').upper().ljust(12)
        title = f.get('title', '')
        
        print(f'{id_str} {sev} {status} {title}')
except Exception as e:
    pass
" "$findings_json"
        ;;
        
    *)
        log_err "Unknown finding command: $cmd"
        exit 1
        ;;
esac
