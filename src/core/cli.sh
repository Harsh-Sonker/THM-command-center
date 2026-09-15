#!/usr/bin/env bash

source "${THM_CORE}/utils.sh"
# thm - CLI Router

cmd="${1:-}"
if [[ -n "$cmd" ]]; then
    shift
fi

show_help() {
    cat << EOF
████████╗██╗  ██╗███╗   ███╗
╚══██╔══╝██║  ██║████╗ ████║
   ██║   ███████║██╔████╔██║
   ██║   ██╔══██║██║╚██╔╝██║
   ██║   ██║  ██║██║ ╚═╝ ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝
         CTF COMMAND CENTER

Usage: thm <command> [options]

Core Commands:
  init          Initialize THM workspace and database
  start         Quick start a room (thm start <room> <ip>)
  status, s     Show current room status
  ctx           Show current context
  jump, enter   Open a shell inside the active room's directory
  tmux          Launch a 4-pane Tmux hacking dashboard
  manual, help  Show the detailed interactive manual

Room & Target Management:
  room, ls      Manage rooms (thm room use <room>, thm ls)
  target, t     Manage targets for current room
  ip            Update the current target's IP address

Tool Execution:
  run, r        Execute a command and log its output
  history, h    View command history for the room

Entities & Evidence:
  flag          Manage flags (set, list, show)
  finding       Log vulnerabilities and findings
  cred          Manage credentials
  note          Add and list notes
  todo          Manage checklist tasks
  loot          Store collected evidence
  screenshot    Store screenshots
  exploit       Store payloads and exploit scripts
  enum          Store enumeration files
  download      Store downloaded files

Advanced Features:
  search        Global search across database
  timeline      Chronological room activity timeline
  report        Generate Markdown executive summary
  export        Export room into a .tar.gz archive
  backup        Backup the global SQLite database
  tools         Inventory check of security tools
  doctor        Run health check on environment

Options:
  --help, -h    Show this help message
  --version     Show version information
EOF
}

case "$cmd" in
    init)
        bash "${THM_CORE}/init.sh" "$@"
        ;;
    start)
        bash "${THM_CORE}/start.sh" "$@"
        ;;
    status|s)
        bash "${THM_CORE}/status.sh" "$@"
        ;;
    ctx)
        room=$(get_current_room)
        target=$(get_current_target)
        echo -e "${BOLD}Room   :${NC} ${room:-None}"
        echo -e "${BOLD}Target :${NC} ${target:-None}"
        ;;
    room)
        bash "${THM_CORE}/room.sh" "$@"
        ;;
    ls)
        bash "${THM_CORE}/room.sh" list "$@"
        ;;
    new)
        bash "${THM_CORE}/room.sh" create "$@"
        ;;
    use)
        bash "${THM_CORE}/room.sh" use "$@"
        ;;
    target|t)
        # If 't' is passed with an IP directly like 'thm t 10.10.10.10', handle it smartly
        if [[ $# -eq 1 && "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            bash "${THM_CORE}/target.sh" use "$1"
        else
            bash "${THM_CORE}/target.sh" "$@"
        fi
        ;;
    run|r)
        bash "${THM_CORE}/run.sh" "$@"
        ;;
    history|h|hist)
        bash "${THM_CORE}/history.sh" "$@"
        ;;
    flag|f)
        bash "${THM_CORE}/flag.sh" "$@"
        ;;
    todo|tdo)
        bash "${THM_CORE}/todo.sh" "$@"
        ;;
    note|n)
        bash "${THM_CORE}/note.sh" "$@"
        ;;
    finding)
        bash "${THM_CORE}/finding.sh" "$@"
        ;;
    cred)
        bash "${THM_CORE}/cred.sh" "$@"
        ;;
    loot)
        bash "${THM_CORE}/loot.sh" "$@"
        ;;
    screenshot)
        bash "${THM_CORE}/screenshot.sh" "$@"
        ;;
    search)
        bash "${THM_CORE}/search.sh" "$@"
        ;;
    timeline)
        bash "${THM_CORE}/timeline.sh" "$@"
        ;;
    report)
        bash "${THM_CORE}/report.sh" "$@"
        ;;
    export)
        bash "${THM_CORE}/export.sh" "$@"
        ;;
    backup)
        bash "${THM_CORE}/backup.sh" "$@"
        ;;
    tmux)
        bash "${THM_CORE}/tmux.sh" "$@"
        ;;
    doctor)
        bash "${THM_CORE}/doctor.sh" "$@"
        ;;
    test)
        bash "${THM_CORE}/test.sh" "$@"
        ;;
    tools)
        bash "${THM_CORE}/tools.sh" "$@"
        ;;
    manual|help)
        bash "${THM_CORE}/manual.sh" "$@"
        ;;
    jump|shell|enter|cd)
        bash "${THM_CORE}/jump.sh" "$@"
        ;;
    ip)
        bash "${THM_CORE}/target.sh" update "$@"
        ;;
    exploit|download|enum|payload|tmp)
        bash "${THM_CORE}/store.sh" "$cmd" "$@"
        ;;
    -h|--help|"")
        show_help
        ;;
    --version)
        echo "THM Command Center v1.0.0"
        ;;
    nmap|gobuster|ffuf|nikto|whatweb|curl|wget)
        bash "${THM_CORE}/run.sh" "$cmd" "$@"
        ;;
    gb)
        bash "${THM_CORE}/run.sh" "gobuster" "$@"
        ;;
    fu)
        bash "${THM_CORE}/run.sh" "ffuf" "$@"
        ;;
    nk)
        bash "${THM_CORE}/run.sh" "nikto" "$@"
        ;;
    ww)
        bash "${THM_CORE}/run.sh" "whatweb" "$@"
        ;;
    *)
        log_err "Unknown command: $cmd"
        echo "Run 'thm --help' for usage."
        exit 1
        ;;
esac
