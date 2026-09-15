#!/usr/bin/env bash
# thm export - Export room data

set -Eeuo pipefail

source "${THM_CORE}/utils.sh"

room_name=$(get_current_room)
if [[ -z "$room_name" ]]; then
    log_err "No active room."
    exit 1
fi

room_dir=$(get_room_dir "$room_name")

if [[ ! -d "$room_dir" ]]; then
    log_err "Room directory not found."
    exit 1
fi

export_dir="${HOME}/TryHackMe_Exports"
mkdir -p "$export_dir"

timestamp=$(date +"%Y%m%d_%H%M%S")
export_file="${export_dir}/${room_name}_export_${timestamp}.tar.gz"

log_info "Exporting room $room_name..."

# Dump specific room data to a JSON inside the room dir before packing
python3 -c "
import sys, json, sqlite3, os

room_name = sys.argv[1]
room_dir = sys.argv[2]
db_path = os.path.expanduser('~/.local/share/thm/thm.db')

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
cursor = conn.cursor()

cursor.execute('SELECT * FROM rooms WHERE name = ?', (room_name,))
room = cursor.fetchone()
if not room: sys.exit(1)
room_id = room['id']

export_data = {'room': dict(room), 'targets': [], 'findings': [], 'notes': []}

cursor.execute('SELECT * FROM targets WHERE room_id = ?', (room_id,))
export_data['targets'] = [dict(row) for row in cursor.fetchall()]

cursor.execute('SELECT * FROM findings WHERE room_id = ?', (room_id,))
export_data['findings'] = [dict(row) for row in cursor.fetchall()]

cursor.execute('SELECT * FROM notes WHERE room_id = ?', (room_id,))
export_data['notes'] = [dict(row) for row in cursor.fetchall()]

with open(os.path.join(room_dir, 'room.json'), 'w') as f:
    json.dump(export_data, f, indent=4)
" "$room_name" "$room_dir"

# Tar the directory
tar -czf "$export_file" -C "$(dirname "$room_dir")" "$(basename "$room_dir")"

log_info "Room exported to $export_file"
