#!/usr/bin/env bash
# thm Command Center Installer

set -Eeuo pipefail

echo "Installing THM Command Center..."

# Check prerequisites
for cmd in bash python3 sqlite3 jq column; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command '$cmd' is missing."
        exit 1
    fi
done

THM_DIR="${HOME}/.local/share/thm"
THM_BIN="${HOME}/.local/bin"

mkdir -p "${THM_DIR}/core"
mkdir -p "${THM_BIN}"

# Copy source to installation directory
cp -r src/core/* "${THM_DIR}/core/"
cp src/thm "${THM_BIN}/thm"
chmod +x "${THM_BIN}/thm"

if [[ -f "src/thm-completion.bash" ]]; then
    mkdir -p "${THM_DIR}/completion"
    cp src/thm-completion.bash "${THM_DIR}/completion/thm-completion.bash"
fi

echo "Installed to ${THM_BIN}/thm"

if [[ ! ":$PATH:" == *":${THM_BIN}:"* ]]; then
    echo "Warning: ${THM_BIN} is not in your PATH."
    echo "Please add it to your ~/.bashrc or ~/.zshrc:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo ""
echo "To enable autocomplete immediately in this session, run:"
echo "  source ${THM_DIR}/completion/thm-completion.bash"
echo ""
echo "To enable autocomplete permanently, add this to your ~/.bashrc:"
echo "  source ${THM_DIR}/completion/thm-completion.bash"
echo ""
echo "Installation complete. Run 'thm init' to setup workspace."
