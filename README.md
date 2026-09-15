# THM CTF Command Center

THM Command Center is a local-first Kali Linux CLI environment designed to manage TryHackMe CTF rooms, commands, evidence, notes, and targets from your terminal. 

## Features
- **Local-First SQLite DB**: Automatically tracks commands, findings, flags, targets, and notes.
- **Universal Run Wrapper**: Run tools like `thm nmap`, `thm gb`, or `thm run curl -I target` and their outputs, timing, and exit codes are automatically logged to the DB and saved in categorized folders.
- **Lightning Fast Context**: Define your room and target once (`thm start <room> <ip>`), and never type them again for subsequent commands.
- **Evidence Management**: Quickly copy screenshots and loot to the correct folder (`thm screenshot add`, `thm loot add`).
- **Markdown Reporting**: Instantly generate executive summaries (`thm report`).
- **Global Search**: Search across your entire workspace, history, and notes (`thm search <keyword>`).

## Quick Start

1. **Install**
```bash
./install.sh
source ~/.local/share/thm/completion/thm-completion.bash
```

2. **Initialize Workspace**
```bash
thm init
```

3. **Start an Engagement**
```bash
thm start Overpass 10.10.10.10
```

4. **Work (Context is automatically applied)**
```bash
thm status                 # View current room/target
thm nmap quick             # Automatically logs to scans/nmap
thm ports                  # (In dev) View nmap ports
thm run curl -i http://10.10.10.10/
thm note add "Interesting endpoint discovered on port 80"
thm flag set user "THM{...}"
thm finding add "Potential SQL Injection" --severity high
```

5. **Generate Report**
```bash
thm report
```

## Structure
All data is stored in `~/TryHackMe/`. Your database is at `~/.local/share/thm/thm.db`.
