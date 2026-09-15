#!/usr/bin/env bash
# thm report - Generate markdown report

set -Eeuo pipefail

room_name=$(get_current_room)
if [[ -z "$room_name" ]]; then
    log_err "No active room."
    exit 1
fi

room_dir=$(get_room_dir "$room_name")
report_dir="${room_dir}/reports"
mkdir -p "$report_dir"

timestamp=$(date +"%Y%m%d_%H%M%S")
report_file="${report_dir}/report_${timestamp}.md"

log_info "Generating report for $room_name..."

# Generate content via Python using sqlite
python3 -c "
import sys, json, sqlite3, os

room_name = sys.argv[1]
report_file = sys.argv[2]
db_path = os.path.expanduser('~/.local/share/thm/thm.db')

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
cursor = conn.cursor()

cursor.execute('SELECT id, created_at FROM rooms WHERE name = ?', (room_name,))
room = cursor.fetchone()
if not room:
    sys.exit(1)
room_id = room['id']

with open(report_file, 'w') as f:
    f.write(f'# THM Report: {room_name}\\n\\n')
    f.write(f'**Generated:** {sys.argv[3]}\\n\\n')
    
    # Targets
    f.write('## Targets\\n')
    cursor.execute('SELECT ip, name FROM targets WHERE room_id = ?', (room_id,))
    for t in cursor.fetchall():
        f.write(f'- {t[\"ip\"]} ({t[\"name\"]})\\n')
    f.write('\\n')
    
    # Findings
    f.write('## Findings\\n')
    cursor.execute('SELECT title, severity, status FROM findings WHERE room_id = ?', (room_id,))
    for finding in cursor.fetchall():
        f.write(f'- **[{finding[\"severity\"].upper()}]** {finding[\"title\"]} ({finding[\"status\"]})\\n')
    f.write('\\n')
    
    # Flags
    f.write('## Flags\\n')
    cursor.execute('SELECT type, found_at FROM flags WHERE room_id = ?', (room_id,))
    for flag in cursor.fetchall():
        f.write(f'- {flag[\"type\"]}: FOUND ({flag[\"found_at\"]})\\n')
    f.write('\\n')
    
    # Notes
    f.write('## Notes\\n')
    cursor.execute('SELECT content, created_at FROM notes WHERE room_id = ?', (room_id,))
    for note in cursor.fetchall():
        f.write(f'> {note[\"created_at\"]}\\n')
        f.write(f'{note[\"content\"]}\\n\\n')
        
conn.close()
" "$room_name" "$report_file" "$timestamp"

log_info "Report generated: $report_file"
