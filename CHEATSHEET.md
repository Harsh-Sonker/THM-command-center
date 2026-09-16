# THM Command Center - Cheatsheet

Welcome to the **THM Command Center**. This tool makes managing TryHackMe CTFs locally on your Kali Linux machine organized and automated. 

Below is the comprehensive list of commands available.

## 1. Setup & Environment
Commands for setting up the tool and configuring your workspace.

| Command | Description |
|---|---|
| `thm init` | Initializes your workspace folder (`~/TryHackMe`) and the local SQLite database. Run this once after installation. |
| `thm doctor` | Runs a health check to verify your SQLite database, workspace directory, and required dependencies (Nmap, Tmux, etc). |
| `thm tools` | Prints an inventory of recommended security tools and shows which ones are installed on your system. |
| `thm test` | Runs the internal integration test suite to verify the database schema and bash scripts work perfectly. |

---

## 2. Room & Context Management
The tool uses a "Context" system. Once you set a room and target, you never have to type them again for subsequent commands.

| Command | Description |
|---|---|
| `thm start <room> <ip>` | **(Most Used)** Automatically creates a room, adds the target IP, and switches your context to it. |
| `thm status` (or `thm s`) | Displays a dashboard of your current active room and target. |
| `thm ctx` | Prints the active Room and Target names concisely. |
| `thm room ls` | Lists all rooms you've created and their statuses. |
| `thm room use <room>` | Switches your active context to a different room. |
| `thm room exit` | Marks your currently active room as 'inactive' without completing it. |
| `thm room finish` | Marks your currently active room as 'completed' (inactive). |
| `thm room activate <room>` | Reactivates a completed room so you can work on it again. |
| `thm target add <ip>` | Adds an additional target IP to your current room. |
| `thm target use <ip>` | Switches your active context to a different target IP within the same room. |
| `thm target update <new_ip>` | Updates the IP address of your currently active target. |
| `thm target update <old_ip> <new_ip>` | Updates the IP address of a specific target. |
| `thm target remove <ip>` | Removes a target from your current room. |

---

## 3. Tool Execution & Output Logging
When you run tools through the `thm run` wrapper, the exact command, start time, execution duration, and exit code are logged in the database, and the output is saved cleanly into categorized folders (e.g., `~/TryHackMe/RoomName/scans/nmap/`).

| Command | Description |
|---|---|
| `thm run <command>` (or `thm r`)| Wraps any command you run, logging its activity and output. Example: `thm run curl -i http://10.10.10.10` |
| `thm <tool> [args]` | We have built-in aliases for popular tools. You can drop the `run` part entirely. Examples:<br>- `thm nmap -sC -sV`<br>- `thm gobuster dir -u http://10.10.10.10/ -w wordlist.txt`<br>- `thm ffuf -u http://10.10.10.10/FUZZ -w wordlist.txt`<br>- `thm nikto -h http://10.10.10.10` |
| `thm history` (or `thm h`) | Displays a chronological table of all commands executed in the current room, including duration and exit codes. |

---

## 4. Entity Management (Flags, Notes, Findings, etc.)
Manage your findings and evidence safely inside the local database.

### 🚩 Flags
Flags are stored in the database and a backup is written to a restricted (`chmod 600`) text file.
| Command | Description |
|---|---|
| `thm flag set <type> <value>` | Saves a flag. Example: `thm flag set user THM{12345}` |
| `thm flag list` | Lists all expected flags (`user`, `root`) and shows if they are FOUND or MISSING. |
| `thm flag show` | Prints the actual values of the flags in plain text. |

### 📝 Notes & TODOs
| Command | Description |
|---|---|
| `thm note add "<text>"` | Adds a quick note. If you omit the text, it will open `nano` (or your `$EDITOR`) to write a multi-line note. |
| `thm note list` | Lists all notes for the current room chronologically. |
| `thm todo add "<task>"` | Adds a task to your to-do list (e.g., "Enumerate SMB on port 445"). |
| `thm todo list` | Displays your to-do list. |
| `thm todo done <id>` | Marks a task as completed based on its ID. |

### 🔍 Findings & Credentials
| Command | Description |
|---|---|
| `thm finding add "<title>" [--severity low\|medium\|high\|critical]` | Logs a vulnerability or finding (e.g., `thm finding add "SQLi in login" --severity critical`). |
| `thm finding list` | Lists all findings color-coded by severity. |
| `thm cred add <user> <pass> [service]` | Saves a credential. Example: `thm cred add admin Password123 SSH` |
| `thm cred list` | Lists all credentials. *Passwords are masked by default for safety.* |
| `thm cred show <id>` | Reveals the plaintext password for a specific credential ID. |

### 📸 Evidence (Loot & Screenshots)
| Command | Description |
|---|---|
| `thm loot add <file>` | Copies a file (e.g. an RSA key or PCAP) directly into the `loot/` folder of the current room. |
| `thm loot list` | Lists all files currently in the `loot/` folder. |
| `thm screenshot add <file>` | Copies a file into the `screenshots/` folder of the current room. |
| `thm screenshot list` | Lists all files currently in the `screenshots/` folder. |
| `thm exploit add <file>` | Copies a payload/exploit script into the `exploits/` folder. |
| `thm download add <file>` | Copies a downloaded file into the `downloads/` folder. |
| `thm enum add <file>` | Copies an enumeration output file into the `enumeration/` folder. |

---

## 5. Advanced Features & Reporting

| Command | Description |
|---|---|
| `thm search <keyword>` | **Global Search.** Searches your *entire database* (across all rooms, targets, notes, findings, and command history) for a specific keyword. |
| `thm timeline` | Generates a chronological breakdown of everything you've done in the current room (commands run, findings added, flags captured). |
| `thm report` | Instantly queries your database and generates a professional Markdown executive summary report in the `reports/` folder of your room. |
| `thm tmux` | Instantly splits your terminal into a pre-configured 4-pane Tmux layout (Main Shell, Exploitation, Enumeration, Notes) named after your active room. |
| `thm backup` | Uses SQLite's native backup mechanism to safely dump a copy of your entire database into `~/.local/share/thm/backups/`. |
| `thm export` | Packages your current room (database records exported as JSON + all scan outputs, notes, and evidence files) into a portable `.tar.gz` archive in `~/TryHackMe_Exports/`. |
