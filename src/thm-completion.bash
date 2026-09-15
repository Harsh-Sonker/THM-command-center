#!/usr/bin/env bash
# thm autocomplete script

_thm_completions() {
    local cur prev words cword
    _init_completion || return
    
    # Basic commands
    local commands="init start status ctx dashboard room target run nmap gobuster ffuf nikto whatweb curl wget history replay ports services note finding cred flag loot evidence screenshot todo search timeline report export backup shell session tmux tools doctor test config"
    
    if [[ $cword -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
        return 0
    fi
    
    # Subcommands
    case "${words[1]}" in
        room)
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=( $(compgen -W "add create list use current info rename archive delete" -- "$cur") )
            elif [[ $cword -eq 3 && "${words[2]}" == "use" ]]; then
                # Fetch rooms from sqlite
                local rooms=$(sqlite3 ~/.local/share/thm/thm.db "SELECT name FROM rooms;" 2>/dev/null)
                COMPREPLY=( $(compgen -W "$rooms" -- "$cur") )
            fi
            ;;
        target)
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=( $(compgen -W "add list use current info remove" -- "$cur") )
            fi
            ;;
        use)
            if [[ $cword -eq 2 ]]; then
                local rooms=$(sqlite3 ~/.local/share/thm/thm.db "SELECT name FROM rooms;" 2>/dev/null)
                COMPREPLY=( $(compgen -W "$rooms" -- "$cur") )
            fi
            ;;
        flag)
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=( $(compgen -W "set list show remove" -- "$cur") )
            elif [[ $cword -eq 3 && "${words[2]}" == "set" ]]; then
                COMPREPLY=( $(compgen -W "user root" -- "$cur") )
            fi
            ;;
        todo|note|finding|cred|loot|screenshot)
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=( $(compgen -W "add list show search remove done" -- "$cur") )
            fi
            ;;
    esac
}

complete -F _thm_completions thm
