#!/usr/bin/env python3
import sqlite3
import sys
import os
from datetime import datetime

# Get THM_DIR from environment or default
THM_DIR = os.environ.get('THM_DIR', os.path.expanduser('~/.local/share/thm'))
DB_PATH = os.path.join(THM_DIR, 'thm.db')

SCHEMA = """
CREATE TABLE IF NOT EXISTS config (
    key TEXT PRIMARY KEY,
    value TEXT
);

CREATE TABLE IF NOT EXISTS rooms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    path TEXT NOT NULL,
    status TEXT DEFAULT 'active',
    difficulty TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS targets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    room_id INTEGER,
    ip TEXT NOT NULL,
    hostname TEXT,
    name TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    target_id INTEGER,
    port INTEGER NOT NULL,
    protocol TEXT DEFAULT 'tcp',
    state TEXT,
    service TEXT,
    version TEXT,
    banner TEXT,
    FOREIGN KEY(target_id) REFERENCES targets(id) ON DELETE CASCADE,
    UNIQUE(target_id, port, protocol)
);

CREATE TABLE IF NOT EXISTS commands (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    room_id INTEGER,
    target_id INTEGER,
    tool TEXT,
    category TEXT,
    full_command TEXT,
    exit_code INTEGER,
    output_path TEXT,
    executed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    duration_sec INTEGER,
    FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE,
    FOREIGN KEY(target_id) REFERENCES targets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS findings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    room_id INTEGER,
    target_id INTEGER,
    title TEXT NOT NULL,
    severity TEXT,
    port INTEGER,
    description TEXT,
    status TEXT DEFAULT 'discovered',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS credentials (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    room_id INTEGER,
    target_id INTEGER,
    username TEXT,
    password TEXT,
    hash TEXT,
    service TEXT,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS flags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    room_id INTEGER,
    type TEXT NOT NULL,
    value TEXT,
    found_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE,
    UNIQUE(room_id, type)
);

CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    room_id INTEGER,
    content TEXT,
    tags TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    room_id INTEGER,
    description TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS evidence (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    room_id INTEGER,
    type TEXT,
    path TEXT NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL,
    entity_id INTEGER NOT NULL,
    tag TEXT NOT NULL,
    UNIQUE(entity_type, entity_id, tag)
);
"""

def get_connection():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_connection()
    try:
        conn.executescript(SCHEMA)
        
        # Check if schema_version exists in config, otherwise set to 1
        cursor = conn.cursor()
        cursor.execute("SELECT value FROM config WHERE key = 'schema_version'")
        if not cursor.fetchone():
            cursor.execute("INSERT INTO config (key, value) VALUES ('schema_version', '1')")
        
        conn.commit()
    except Exception as e:
        print(f"Error initializing DB: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        conn.close()

def create_room(name, path):
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("INSERT INTO rooms (name, path) VALUES (?, ?)", (name, path))
        conn.commit()
        print(cursor.lastrowid)
    except sqlite3.IntegrityError:
        print("Error: Room already exists.", file=sys.stderr)
        sys.exit(1)
    finally:
        conn.close()

def list_rooms():
    import json
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id, name, status, difficulty, created_at FROM rooms ORDER BY created_at DESC")
    rooms = [dict(row) for row in cursor.fetchall()]
    print(json.dumps(rooms))
    conn.close()

def get_room(name):
    import json
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM rooms WHERE name = ?", (name,))
    room = cursor.fetchone()
    if room:
        print(json.dumps(dict(room)))
    else:
        sys.exit(1)
    conn.close()

def update_room_status(name, status):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE rooms SET status = ? WHERE name = ?", (status, name))
    conn.commit()
    conn.close()

def create_target(room_name, ip, name=""):
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM rooms WHERE name = ?", (room_name,))
        room = cursor.fetchone()
        if not room:
            print(f"Error: Room '{room_name}' not found.", file=sys.stderr)
            sys.exit(1)
            
        cursor.execute("INSERT INTO targets (room_id, ip, name) VALUES (?, ?, ?)", (room["id"], ip, name))
        conn.commit()
        print(cursor.lastrowid)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        conn.close()

def list_targets(room_name):
    import json
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM rooms WHERE name = ?", (room_name,))
    room = cursor.fetchone()
    if not room:
        print("[]")
        return
        
    cursor.execute("SELECT id, ip, hostname, name, created_at FROM targets WHERE room_id = ? ORDER BY created_at ASC", (room["id"],))
    targets = [dict(row) for row in cursor.fetchall()]
    print(json.dumps(targets))
    conn.close()

def log_command(room_name, target_ip, tool, category, full_command, exit_code, output_path, duration_sec):
    conn = get_connection()
    try:
        cursor = conn.cursor()
        
        # Get room_id
        cursor.execute("SELECT id FROM rooms WHERE name = ?", (room_name,))
        room = cursor.fetchone()
        if not room:
            sys.exit(1)
            
        room_id = room["id"]
        target_id = None
        
        # Get target_id if target_ip is provided
        if target_ip:
            cursor.execute("SELECT id FROM targets WHERE room_id = ? AND ip = ?", (room_id, target_ip))
            target = cursor.fetchone()
            if target:
                target_id = target["id"]
                
        cursor.execute("""
            INSERT INTO commands 
            (room_id, target_id, tool, category, full_command, exit_code, output_path, duration_sec) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (room_id, target_id, tool, category, full_command, exit_code, output_path, duration_sec))
        
        conn.commit()
        print(cursor.lastrowid)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        conn.close()

def list_history(room_name=None, tool=None):
    import json
    conn = get_connection()
    cursor = conn.cursor()
    
    query = """
        SELECT c.id, c.tool, c.full_command, c.exit_code, c.executed_at, t.ip as target_ip 
        FROM commands c
        LEFT JOIN targets t ON c.target_id = t.id
    """
    
    params = []
    where_clauses = []
    
    if room_name:
        cursor.execute("SELECT id FROM rooms WHERE name = ?", (room_name,))
        room = cursor.fetchone()
        if room:
            where_clauses.append("c.room_id = ?")
            params.append(room["id"])
            
    if tool:
        where_clauses.append("c.tool = ?")
        params.append(tool)
        
    if where_clauses:
        query += " WHERE " + " AND ".join(where_clauses)
        
    query += " ORDER BY c.executed_at DESC"
    
    cursor.execute(query, params)
    commands = [dict(row) for row in cursor.fetchall()]
    print(json.dumps(commands))
    conn.close()

# Entity management
def get_room_id(room_name):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM rooms WHERE name = ?", (room_name,))
    room = cursor.fetchone()
    conn.close()
    if room:
        return room["id"]
    return None

def flag_set(room_name, type, value):
    room_id = get_room_id(room_name)
    if not room_id: return
    
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO flags (room_id, type, value) 
        VALUES (?, ?, ?) 
        ON CONFLICT(room_id, type) DO UPDATE SET value=excluded.value, found_at=CURRENT_TIMESTAMP
    """, (room_id, type, value))
    conn.commit()
    conn.close()

def flag_list(room_name):
    import json
    room_id = get_room_id(room_name)
    if not room_id: return
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT type, found_at, value FROM flags WHERE room_id = ?", (room_id,))
    flags = [dict(row) for row in cursor.fetchall()]
    print(json.dumps(flags))
    conn.close()

def todo_add(room_name, desc):
    room_id = get_room_id(room_name)
    if not room_id: return
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO tasks (room_id, description) VALUES (?, ?)", (room_id, desc))
    conn.commit()
    print(cursor.lastrowid)
    conn.close()

def todo_list(room_name):
    import json
    room_id = get_room_id(room_name)
    if not room_id: return
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id, description, status FROM tasks WHERE room_id = ?", (room_id,))
    print(json.dumps([dict(row) for row in cursor.fetchall()]))
    conn.close()

def todo_done(room_name, task_id):
    room_id = get_room_id(room_name)
    if not room_id: return
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE tasks SET status='completed' WHERE room_id=? AND id=?", (room_id, task_id))
    conn.commit()
    conn.close()

def create_target(room_name, ip, name=""):
    room_id = get_room_id(room_name)
    if not room_id: return
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT OR IGNORE INTO targets (room_id, ip, name) VALUES (?, ?, ?)", (room_id, ip, name))
    conn.commit()
    conn.close()

def target_remove(room_name, ip):
    room_id = get_room_id(room_name)
    if not room_id: return
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM targets WHERE room_id = ? AND ip = ?", (room_id, ip))
    conn.commit()
    conn.close()

def update_target_ip(room_name, old_ip, new_ip):
    room_id = get_room_id(room_name)
    if not room_id: return
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE targets SET ip = ? WHERE room_id = ? AND ip = ?", (new_ip, room_id, old_ip))
    conn.commit()
    conn.close()

def note_add(room_name, content):
    room_id = get_room_id(room_name)
    if not room_id: return
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO notes (room_id, content) VALUES (?, ?)", (room_id, content))
    conn.commit()
    print(cursor.lastrowid)
    conn.close()

def note_list(room_name):
    import json
    room_id = get_room_id(room_name)
    if not room_id: return
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id, content, created_at FROM notes WHERE room_id = ?", (room_id,))
    print(json.dumps([dict(row) for row in cursor.fetchall()]))
    conn.close()

def finding_add(room_name, title, severity):
    room_id = get_room_id(room_name)
    if not room_id: return
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO findings (room_id, title, severity) VALUES (?, ?, ?)", (room_id, title, severity))
    conn.commit()
    print(cursor.lastrowid)
    conn.close()

def finding_list(room_name):
    import json
    room_id = get_room_id(room_name)
    if not room_id: return
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id, title, severity, status FROM findings WHERE room_id = ?", (room_id,))
    print(json.dumps([dict(row) for row in cursor.fetchall()]))
    conn.close()

def cred_add(room_name, username, password, service):
    room_id = get_room_id(room_name)
    if not room_id: return
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO credentials (room_id, username, password, service) VALUES (?, ?, ?, ?)", (room_id, username, password, service))
    conn.commit()
    print(cursor.lastrowid)
    conn.close()

def cred_list(room_name):
    import json
    room_id = get_room_id(room_name)
    if not room_id: return
    conn = get_connection()
    cursor = conn.cursor()
    # Mask passwords by default in lists
    cursor.execute("SELECT id, username, service FROM credentials WHERE room_id = ?", (room_id,))
    print(json.dumps([dict(row) for row in cursor.fetchall()]))
    conn.close()
    
def cred_show(room_name, cred_id):
    import json
    room_id = get_room_id(room_name)
    if not room_id: return
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM credentials WHERE room_id = ? AND id = ?", (room_id, cred_id))
    c = cursor.fetchone()
    if c:
        print(json.dumps(dict(c)))
    conn.close()

def timeline_list(room_name):
    import json
    room_id = get_room_id(room_name)
    if not room_id: return
    
    conn = get_connection()
    cursor = conn.cursor()
    
    # Query all events and UNION them
    query = """
    SELECT 'Command' as type, executed_at as timestamp, full_command as details FROM commands WHERE room_id = ?
    UNION ALL
    SELECT 'Finding' as type, created_at as timestamp, title as details FROM findings WHERE room_id = ?
    UNION ALL
    SELECT 'Note' as type, created_at as timestamp, substr(content, 1, 50) as details FROM notes WHERE room_id = ?
    UNION ALL
    SELECT 'Flag' as type, found_at as timestamp, type as details FROM flags WHERE room_id = ?
    UNION ALL
    SELECT 'Credential' as type, created_at as timestamp, username || '@' || service as details FROM credentials WHERE room_id = ?
    UNION ALL
    SELECT 'Target' as type, created_at as timestamp, ip as details FROM targets WHERE room_id = ?
    ORDER BY timestamp DESC
    """
    
    cursor.execute(query, (room_id, room_id, room_id, room_id, room_id, room_id))
    events = [dict(row) for row in cursor.fetchall()]
    print(json.dumps(events))
    conn.close()

def global_search(keyword):
    import json
    conn = get_connection()
    cursor = conn.cursor()
    
    keyword = f"%{keyword}%"
    results = []
    
    # Search Rooms
    cursor.execute("SELECT name, status, created_at FROM rooms WHERE name LIKE ?", (keyword,))
    for r in cursor.fetchall():
        results.append({"type": "Room", "room": r["name"], "detail": r["name"], "timestamp": r["created_at"]})
        
    # Search Targets
    cursor.execute("SELECT r.name as room, t.ip, t.created_at FROM targets t JOIN rooms r ON t.room_id = r.id WHERE t.ip LIKE ? OR t.name LIKE ?", (keyword, keyword))
    for r in cursor.fetchall():
        results.append({"type": "Target", "room": r["room"], "detail": r["ip"], "timestamp": r["created_at"]})
        
    # Search Notes
    cursor.execute("SELECT r.name as room, n.content, n.created_at FROM notes n JOIN rooms r ON n.room_id = r.id WHERE n.content LIKE ?", (keyword,))
    for r in cursor.fetchall():
        results.append({"type": "Note", "room": r["room"], "detail": r["content"][:100], "timestamp": r["created_at"]})
        
    # Search Findings
    cursor.execute("SELECT r.name as room, f.title, f.created_at FROM findings f JOIN rooms r ON f.room_id = r.id WHERE f.title LIKE ? OR f.description LIKE ?", (keyword, keyword))
    for r in cursor.fetchall():
        results.append({"type": "Finding", "room": r["room"], "detail": r["title"], "timestamp": r["created_at"]})
        
    # Search Credentials
    cursor.execute("SELECT r.name as room, c.username, c.service, c.created_at FROM credentials c JOIN rooms r ON c.room_id = r.id WHERE c.username LIKE ? OR c.service LIKE ? OR c.notes LIKE ?", (keyword, keyword, keyword))
    for r in cursor.fetchall():
        service = r["service"] if r["service"] else "Unknown"
        results.append({"type": "Credential", "room": r["room"], "detail": f"{r['username']}@{service}", "timestamp": r["created_at"]})
        
    # Search Commands
    cursor.execute("SELECT r.name as room, c.full_command, c.executed_at FROM commands c JOIN rooms r ON c.room_id = r.id WHERE c.full_command LIKE ?", (keyword,))
    for r in cursor.fetchall():
        results.append({"type": "Command", "room": r["room"], "detail": r["full_command"][:100], "timestamp": r["executed_at"]})
        
    results.sort(key=lambda x: x["timestamp"], reverse=True)
    print(json.dumps(results))
    conn.close()

def main():
    if len(sys.argv) < 2:
        print("Usage: db.py <command> [args]", file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "init":
        init_db()
    elif cmd == "room_create":
        if len(sys.argv) < 4: sys.exit(1)
        create_room(sys.argv[2], sys.argv[3])
    elif cmd == "room_list":
        list_rooms()
    elif cmd == "room_get":
        if len(sys.argv) < 3: sys.exit(1)
        get_room(sys.argv[2])
    elif cmd == "room_update_status":
        if len(sys.argv) < 4: sys.exit(1)
        update_room_status(sys.argv[2], sys.argv[3])
    elif cmd == "target_create":
        if len(sys.argv) < 4: sys.exit(1)
        create_target(sys.argv[2], sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else "")
    elif cmd == "target_list":
        if len(sys.argv) < 3: sys.exit(1)
        list_targets(sys.argv[2])
    elif cmd == "target_remove":
        if len(sys.argv) < 4: sys.exit(1)
        target_remove(sys.argv[2], sys.argv[3])
    elif cmd == "target_update_ip":
        if len(sys.argv) < 5: sys.exit(1)
        update_target_ip(sys.argv[2], sys.argv[3], sys.argv[4])
    elif cmd == "command_log":
        if len(sys.argv) < 10: sys.exit(1)
        log_command(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6], int(sys.argv[7]), sys.argv[8], int(sys.argv[9]))
    elif cmd == "command_list":
        room_name = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] != "" else None
        tool = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] != "" else None
        list_history(room_name, tool)
    elif cmd == "flag_set":
        if len(sys.argv) < 5: sys.exit(1)
        flag_set(sys.argv[2], sys.argv[3], sys.argv[4])
    elif cmd == "flag_list":
        if len(sys.argv) < 3: sys.exit(1)
        flag_list(sys.argv[2])
    elif cmd == "todo_add":
        if len(sys.argv) < 4: sys.exit(1)
        todo_add(sys.argv[2], sys.argv[3])
    elif cmd == "todo_list":
        if len(sys.argv) < 3: sys.exit(1)
        todo_list(sys.argv[2])
    elif cmd == "todo_done":
        if len(sys.argv) < 4: sys.exit(1)
        todo_done(sys.argv[2], sys.argv[3])
    elif cmd == "note_add":
        if len(sys.argv) < 4: sys.exit(1)
        note_add(sys.argv[2], sys.argv[3])
    elif cmd == "note_list":
        if len(sys.argv) < 3: sys.exit(1)
        note_list(sys.argv[2])
    elif cmd == "finding_add":
        if len(sys.argv) < 5: sys.exit(1)
        finding_add(sys.argv[2], sys.argv[3], sys.argv[4])
    elif cmd == "finding_list":
        if len(sys.argv) < 3: sys.exit(1)
        finding_list(sys.argv[2])
    elif cmd == "cred_add":
        if len(sys.argv) < 6: sys.exit(1)
        cred_add(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
    elif cmd == "cred_list":
        if len(sys.argv) < 3: sys.exit(1)
        cred_list(sys.argv[2])
    elif cmd == "cred_show":
        if len(sys.argv) < 4: sys.exit(1)
        cred_show(sys.argv[2], sys.argv[3])
    elif cmd == "timeline":
        if len(sys.argv) < 3: sys.exit(1)
        timeline_list(sys.argv[2])
    elif cmd == "search":
        if len(sys.argv) < 3: sys.exit(1)
        global_search(sys.argv[2])
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
