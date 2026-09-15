#!/usr/bin/env bash
# thm run - Universal command execution and logging wrapper

set -Eeuo pipefail

if [[ $# -eq 0 ]]; then
    log_err "Usage: thm run <command> [args...]"
    exit 1
fi

room_name=$(get_current_room)
target_ip=$(get_current_target)

if [[ -z "$room_name" ]]; then
    log_err "No active room. Commands must be run within a room context."
    exit 1
fi

# The command to execute
cmd_array=("$@")
tool_name="${cmd_array[0]}"
full_cmd_str="${cmd_array[*]}"

# Determine category and specific output subdirectory based on tool name
category="other"
out_dir="commands"
case "$tool_name" in
    nmap)
        category="scans/nmap"
        out_dir="scans/nmap"
        ;;
    gobuster)
        category="scans/gobuster"
        out_dir="scans/gobuster"
        ;;
    ffuf)
        category="scans/ffuf"
        out_dir="scans/ffuf"
        ;;
    nikto)
        category="scans/nikto"
        out_dir="scans/nikto"
        ;;
    curl|wget|whatweb)
        category="scans/web"
        out_dir="scans/web"
        ;;
    sqlmap|hydra)
        category="scans/vuln"
        out_dir="scans/vuln"
        ;;
esac

# Generate unique filename for output
timestamp=$(date +"%Y%m%d_%H%M%S")
room_dir=$(get_room_dir "$room_name")

# Create output dir if it doesn't exist
full_out_dir="${room_dir}/${out_dir}"
mkdir -p "$full_out_dir"

output_file="${full_out_dir}/${timestamp}_${tool_name}.txt"

log_info "Executing: ${full_cmd_str}"
log_info "Logging to: ${output_file}"

# Execute the command, stream output to stdout, and tee to the file
start_time=$(date +%s)

# Temporarily disable pipefail so that if the command fails, tee doesn't crash the script early
set +o pipefail
"${cmd_array[@]}" 2>&1 | tee "$output_file"

# Capture the exit code of the actual command (PIPESTATUS[0])
exit_code=${PIPESTATUS[0]}
set -o pipefail

end_time=$(date +%s)
duration=$((end_time - start_time))

# Log to database
run_db command_log "$room_name" "${target_ip:-}" "$tool_name" "$category" "$full_cmd_str" "$exit_code" "$output_file" "$duration" > /dev/null

if [[ $exit_code -eq 0 ]]; then
    log_info "Command completed successfully in ${duration}s"
else
    log_warn "Command exited with status $exit_code after ${duration}s"
fi

# Post-processing (Tool Specific Wrappers Integration)
# Check if there is a specific handler for this tool
handler_script="${THM_CORE}/tools/${tool_name}.sh"
if [[ -f "$handler_script" ]]; then
    # Pass control to post-processor, it can parse output files, etc.
    bash "$handler_script" post_process "$room_name" "${target_ip:-}" "$output_file" "$full_cmd_str" || true
fi

# Exit with the original command's exit code
exit $exit_code
