#!/usr/bin/env bash
# thm test - Internal test suite

set -Eeuo pipefail

log_info "Running THM Test Suite..."
echo "--------------------------------------------------------"

pass=0
fail=0

assert_cmd() {
    local cmd="$1"
    local desc="$2"
    
    # Run the command silently
    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "[\033[0;32mPASS\033[0m] $desc"
        ((pass++))
    else
        echo -e "[\033[0;31mFAIL\033[0m] $desc"
        ((fail++))
    fi
}

# Syntax checks
assert_cmd "bash -n ${THM_CORE}/cli.sh" "Syntax check: cli.sh"
assert_cmd "bash -n ${THM_CORE}/init.sh" "Syntax check: init.sh"
assert_cmd "bash -n ${THM_CORE}/run.sh" "Syntax check: run.sh"
assert_cmd "python3 -m py_compile ${THM_CORE}/db.py" "Syntax check: db.py"

# Integration checks
export THM_TEST_MODE=1
test_room="test_room_$$"

assert_cmd "thm room create $test_room" "Room creation"
assert_cmd "thm room current | grep -q $test_room" "Room context switch"
assert_cmd "thm target add 127.0.0.1" "Target creation"
assert_cmd "thm flag set user 'thm{test}'" "Flag storage"
assert_cmd "thm note add 'This is a test note'" "Note storage"

# Cleanup
thm room delete "$test_room" >/dev/null 2>&1 || true

echo "--------------------------------------------------------"
if [[ $fail -eq 0 ]]; then
    log_info "All tests passed ($pass/$(($pass+$fail)))."
else
    log_err "$fail tests failed."
    exit 1
fi
