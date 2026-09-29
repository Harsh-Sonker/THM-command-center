# Automating Your CTF Workflow: Building a Local-First Command Center for TryHackMe

If you spend any time playing Capture The Flag (CTF) challenges on platforms like TryHackMe or HackTheBox, you know that the hardest part isn't always the hacking—it's the organization. 

Picture this: You are halfway through an engagement. You have five terminal tabs open. One is running an `nmap` scan that you forgot to pipe into a text file, meaning the output will be lost as soon as you clear the screen. Another is running `gobuster`. You have a random `passwords.txt` file sitting on your Desktop, and you constantly have to copy-paste the target IP `10.10.x.x` into every single command you type. 

It gets messy, fast. 

As a cybersecurity enthusiast, I realized I was spending way too much time managing files and typing boilerplate commands. I wanted to focus on the actual exploitation. So, I built the **THM Command Center**—a local-first CLI environment designed to act as a personal hacking OS on Kali Linux.

In this article, I'll walk you through why I built it, how it works, and how it can completely streamline your pentesting workflow.

---

## 🧠 The Logic: The Old Way vs. The Automated Way

Let's look at a common scenario for absolute beginners.

**The Old Way:**
When you start a machine called "Overpass," you manually run `mkdir Overpass`. Then you go inside and run `mkdir scans`. You copy the IP address from the TryHackMe dashboard. You type `nmap -sC -sV 10.10.10.10 > scans/nmap.txt`. Then you open a new tab, export an IP variable, and try to keep track of your notes using `nano notes.txt`. You accidentally close a tab, and your command history for that specific target is gone forever.

**The THM Command Center Way:**
With the automated CLI tool, you simply tell your system you are starting an engagement:
```bash
thm start Overpass 10.10.10.10
```
That single command does four things instantly:
1. It creates the optimal folder structure (`scans/`, `exploits/`, `loot/`) for the room.
2. It sets a global "Context" in the background. It remembers your target IP across *all* your terminal tabs.
3. It registers the target in a local SQLite database.
4. It drops you directly into the workspace.

Now, instead of typing a massive Nmap command, you just type:
```bash
thm nmap -sC -sV
```
The tool injects the IP address for you, runs Nmap, logs the exact command you ran into the database, measures how long it took, and automatically saves the output into your `scans/nmap/` directory.

---

## ✨ Killer Features of the Tool

I wanted this tool to be the ultimate companion for CTFs, so I packed it with features that solve real pain points:

### 1. 100% Local SQLite Database 💾
There are no APIs, no cloud syncs, and no telemetry. Everything is stored locally on your Kali machine in a fast SQLite database (`~/.local/share/thm/thm.db`). This database tracks:
- The rooms you are working on.
- The commands you've executed (Command History).
- Flags, Credentials, and Findings.

### 2. Context-Aware Execution 🎯
Because the tool remembers your active room and target IP, you never have to type them. 
Found a weird endpoint? Just type:
```bash
thm run curl -i http://target/api/v1/users
```
The word `target` is dynamically replaced with the actual IP address by the tool before it runs.

### 3. Entity Tracking 📓
Instead of keeping a dozen scattered text files, you manage your evidence straight from the terminal.
- Got a flag? `thm flag set user "THM{flag_here}"`
- Found a password? `thm cred add admin secret123`
- Need to save an exploit script? `thm exploit add reverse_shell.php`

### 4. Global Search Engine 🔍
If you are doing a massive CTF path (like the Offensive Pentesting path) and you suddenly remember seeing a specific credential but forgot which room it was in, you can search your entire history:
```bash
thm search secret123
```
This instantly searches all your rooms, notes, commands, and credentials to find the match.

### 5. Markdown Reporting 📄
At the end of an engagement, writing the report is tedious. Since all your findings, flags, notes, and commands are in the database, you can generate a professional Markdown executive summary with one command:
```bash
thm report
```
This saves an incredible amount of time, especially for write-ups!

---

## 🚀 How to Get Started

The tool is completely open-source and free to use. To install it on your Kali Linux machine, just run:

```bash
git clone https://github.com/Harsh-Sonker/THM-command-center.git
cd THM-command-center
chmod +x install.sh
./install.sh
```

After installation, run `thm init` to build your environment, and you are ready to hack! Check your status at any time with `thm status`.

## Final Thoughts

Building the THM Command Center was an incredible learning experience in bash scripting, Python integration, and database management. But more importantly, it has made hacking *fun* again by removing the tedious administrative work from the equation.

If you try it out, I'd love to hear your feedback! Feel free to star the repository, open issues, or contribute pull requests.

Happy Hacking! 💻🛡️

🔗 **GitHub Repository:** [Insert your GitHub Link Here]
