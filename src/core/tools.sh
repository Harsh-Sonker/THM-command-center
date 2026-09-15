#!/usr/bin/env bash
# thm tools - Security tool inventory

set -Eeuo pipefail

log_info "Security Tool Inventory"
echo "--------------------------------------------------------"

check_sec_cmd() {
    local cmd="$1"
    local name="${2:-$1}"
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${name} \t\t [\033[0;32mOK\033[0m]"
    else
        echo -e "${name} \t\t [\033[0;31mMISSING\033[0m]"
    fi
}

check_sec_cmd "nmap" "Nmap"
check_sec_cmd "gobuster" "Gobuster"
check_sec_cmd "ffuf" "FFUF"
check_sec_cmd "nikto" "Nikto"
check_sec_cmd "sqlmap" "SQLMap"
check_sec_cmd "hydra" "Hydra"
check_sec_cmd "smbclient" "SMBClient"
check_sec_cmd "enum4linux" "Enum4linux"
check_sec_cmd "whatweb" "WhatWeb"
check_sec_cmd "feroxbuster" "Feroxbuster"
check_sec_cmd "hashcat" "Hashcat"
check_sec_cmd "john" "John The Ripper"
check_sec_cmd "tmux" "Tmux"
check_sec_cmd "script" "Script"

echo "--------------------------------------------------------"
echo -e "${YELLOW}Note:${NC} THM Command Center uses these tools when available."
echo "Use your OS package manager (e.g. apt) to install missing tools."
