import os, glob

core_dir = 'src/core'
for file in glob.glob(os.path.join(core_dir, '*.sh')):
    if os.path.basename(file) == 'utils.sh':
        continue
    
    with open(file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    # Check if already sourced
    already_sourced = any('source "${THM_CORE}/utils.sh"' in line for line in lines)
    if already_sourced:
        continue
        
    new_lines = []
    inserted = False
    for line in lines:
        new_lines.append(line)
        if line.startswith('set -Eeuo pipefail') and not inserted:
            new_lines.append('\nsource "${THM_CORE}/utils.sh"\n')
            inserted = True
            
    if not inserted:
        if new_lines and new_lines[0].startswith('#!/'):
            new_lines.insert(1, '\nsource "${THM_CORE}/utils.sh"\n')
        else:
            new_lines.insert(0, 'source "${THM_CORE}/utils.sh"\n')
        
    with open(file, 'w', encoding='utf-8', newline='\n') as f:
        f.writelines(new_lines)

print("Added utils.sh import to all scripts.")
