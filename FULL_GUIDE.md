<div align="center">
  <h1>🎯 THM CTF Command Center - User Guide</h1>
  
  <p><b>The ultimate local-first CLI environment for mastering TryHackMe & HackTheBox on Kali Linux.</b></p>
  
  <p>
    <img src="https://img.shields.io/badge/Language-BASH-brightgreen" alt="Language">
    <img src="https://img.shields.io/badge/Database-SQLITE-blue" alt="Database">
    <img src="https://img.shields.io/badge/OS-KALI%20LINUX-grey" alt="OS">
    <img src="https://img.shields.io/badge/License-MIT-blue" alt="License">
  </p>
  
  <p><i>Say goodbye to messy terminal tabs, lost scan outputs, and scattered notes.</i></p>
</div>

---

Welcome to the **THM Command Center** Detailed User Guide. This tool acts as a "Local OS" specifically designed for managing TryHackMe (and HackTheBox) CTFs directly on your Kali Linux machine. It automates workspace creation, context switching, command logging, and evidence management using a local SQLite database.

Below is the complete, start-to-finish workflow detailing the usage of **every single command** available in the tool.

---

## 1. Installation & Environment Setup

Before starting your first CTF, you need to ensure the tool is correctly configured.

### `thm init`
**Usage:** `thm init`
Initializes your workspace folder (default: `~/TryHackMe`), creates the local SQLite database, and sets up required background directories (`~/.local/share/thm`). Run this **once** after installation.

### `thm doctor`
**Usage:** `thm doctor`
Runs a health check on your environment. It verifies that your SQLite database is accessible, the workspace directories exist, and that required core dependencies (like Tmux) are installed.

### `thm tools`
**Usage:** `thm tools`
Prints an inventory checklist of recommended security tools (like Nmap, Gobuster, Ffuf, Nikto, etc.) and shows which ones are currently installed on your system.

### `thm test`
**Usage:** `thm test`
Executes the internal integration test suite. This ensures the database schema is intact and all bash scripts are functioning perfectly.

### `thm --version` & `thm --help`
**Usage:** `thm --version` or `thm -h` / `thm --help`
Displays the current version of THM Command Center or shows the quick command reference.

---

## 2. Room & Context Management

The core philosophy of this tool is the "Context". By telling the tool which Room and IP you are currently working on, you never have to type them again in subsequent commands.

### `thm start` (The recommended way to begin)
**Usage:** `thm start <room_name> <target_ip>`
**Example:** `thm start Overpass 10.10.5.5`
This is your most used command. It automatically:
1. Creates the room in the database.
2. Adds the target IP to the room.
3. Builds a clean, standardized folder structure for the room at `~/TryHackMe/<room_name>/`.
4. Sets your global active context to this room and target.

### `thm status` (or `thm s`)
**Usage:** `thm status`
Displays a clean dashboard showing your currently active room, the active target IP, and basic statistics for the room.

### `thm ctx`
**Usage:** `thm ctx`
A quicker version of `status`. It simply prints the currently active Room and Target names.

### `thm jump` (or `thm enter`, `thm shell`, `thm cd`)
**Usage:** `thm jump`
Instantly drops you into a new shell located precisely inside the active room's workspace directory (`~/TryHackMe/<room_name>`).

### `thm tmux`
**Usage:** `thm tmux`
Instantly splits your terminal into a perfectly configured 4-pane Tmux layout named after your active room. The panes are usually split into: Main Shell, Exploitation, Enumeration, and Notes.

### Detailed Room Commands (`thm room`)
If you want granular control over rooms, use the `thm room` subcommands:
- **`thm room new <room>`**: Creates a new room without switching to it.
- **`thm room ls`** (or `thm ls`): Lists all rooms you've ever created and their statuses (Active, Inactive, Completed).
- **`thm room use <room>`**: Switches your active context to a different room.
- **`thm room exit`**: Exits the current room context, leaving you with no active room.
- **`thm room finish`**: Marks your currently active room as 'completed' and exits the context.
- **`thm room activate <room>`**: Reactivates a 'completed' room so you can work on it again.

### Detailed Target Commands (`thm target` & `thm ip`)
- **`thm target add <ip>`**: Adds an additional target IP to your current room (useful for networks with multiple machines).
- **`thm target use <ip>`**: Switches your active context to a different target IP within the same room.
- **`thm ip <ip>`**: A crucial shortcut! If your TryHackMe machine expires and you get a new IP, simply run `thm ip <new_ip>` to seamlessly update the current target without losing any history.

---

## 3. Tool Execution & Output Logging

When you run tools through THM Command Center, the exact command, start time, execution duration, exit code, and full output (stdout & stderr) are automatically logged.

### `thm run` (or `thm r`)
**Usage:** `thm run <command>`
**Example:** `thm run curl -i http://10.10.99.10/api`
Wraps any arbitrary command you run. It logs the activity and saves the output to the `commands/` directory inside your room's workspace.

### Tool Aliases (e.g., `thm nmap`, `thm gobuster`)
**Usage:** `thm <tool> [args]`
**Example:** `thm nmap -sC -sV -p-`
You can drop the `run` keyword for popular tools. The wrapper automatically routes the output to categorized folders (e.g., `~/TryHackMe/<room_name>/scans/nmap/`).
Supported native aliases include: `nmap`, `gobuster` (or `gb`), `ffuf` (or `fu`), `nikto` (or `nk`), `whatweb` (or `ww`), `curl`, `wget`.

### `thm history` (or `thm h`, `thm hist`)
**Usage:** `thm history`
Displays a chronological, tabular history of all commands executed in the current room, showing the exact command, duration, and exit codes.

---

## 4. Entity & Evidence Management

Keep track of all your findings safely inside the local database instead of scattered text files.

### 🚩 Flags
- **`thm flag set <type> <value>`**: Saves a flag. (Example: `thm flag set user THM{12345}`). This saves to the DB and creates a restricted backup file.
- **`thm flag list`**: Lists expected flags (user, root) and shows if they are FOUND or MISSING.
- **`thm flag show`**: Prints the actual plaintext values of the flags you've captured.

### 📝 Notes
- **`thm note add "<text>"`**: Adds a quick note. (Example: `thm note add "Port 80 is running Apache"`). If you run `thm note add` without text, it opens your `$EDITOR` (like nano) for multi-line notes.
- **`thm note list`** (or `thm note`): Lists all notes for the current room chronologically.

### ✅ Checklist (TODO)
- **`thm todo add "<task>"`**: Adds a task to your checklist. (Example: `thm todo add "Enumerate SMB on port 445"`).
- **`thm todo list`** (or `thm todo`): Displays your pending and completed tasks.
- **`thm todo done <id>`**: Marks a specific task as completed based on its ID.

### 🔍 Findings
- **`thm finding add "<title>" [--severity low|medium|high|critical]`**: Logs a vulnerability. (Example: `thm finding add "SQLi in login" --severity critical`).
- **`thm finding list`** (or `thm finding`): Lists all findings color-coded by their severity.

### 🔑 Credentials
- **`thm cred add <user> <pass> [service]`**: Saves a discovered credential. (Example: `thm cred add admin Password123 SSH`).
- **`thm cred list`** (or `thm cred`): Lists all credentials. *Passwords are masked (`********`) by default for safety.*
- **`thm cred show <id>`**: Reveals the plaintext password for a specific credential ID.

### 📸 Evidence & Files
Store downloaded files, screenshots, and exploits instantly without typing long paths.
- **`thm loot add <file>`**: Copies a file (e.g., `id_rsa`) into the `loot/` folder of the current room.
- **`thm screenshot add <file>`**: Copies an image into the `screenshots/` folder.
- **`thm exploit add <file>`**: Copies a payload into the `exploits/` folder.
- **`thm download add <file>`**: Copies a downloaded artifact into the `downloads/` folder.
- **`thm enum add <file>`**: Copies an enumeration output file into the `enumeration/` folder.

To view the contents of any of these folders, simply run their list equivalent:
- `thm loot list`
- `thm screenshot list`
- `thm exploit list`
- `thm download list`
- `thm enum list`

---

## 5. Advanced Features & Reporting

### `thm search`
**Usage:** `thm search <keyword>`
**Example:** `thm search Password123`
Performs a global search across your *entire database* (all rooms, targets, notes, findings, credentials, and command history) for the specified keyword.

### `thm timeline`
**Usage:** `thm timeline`
Generates a detailed, chronological breakdown of everything you have done in the current room (commands run, flags captured, findings added).

### `thm report`
**Usage:** `thm report`
Instantly queries the database and generates a professional, Markdown-formatted executive summary report containing your findings, flags, credentials, and notes. The report is saved directly to the `reports/` folder of your active room.

### `thm backup`
**Usage:** `thm backup`
Uses SQLite's native backup mechanism to safely dump a copy of your entire database into `~/.local/share/thm/backups/`. Crucial for ensuring you never lose your progress.

### `thm export`
**Usage:** `thm export`
Packages your current active room (exporting database records as JSON and bundling all scan outputs, notes, and evidence files) into a highly portable `.tar.gz` archive, saved in `~/TryHackMe_Exports/`. Perfect for archiving completed rooms.

### `thm manual` (or `thm help`)
**Usage:** `thm manual`
Shows the interactive, detailed manual directly in the terminal for quick reference.

---
*Happy Hacking! Let the THM Command Center handle the logistics while you focus on the CTF.*
