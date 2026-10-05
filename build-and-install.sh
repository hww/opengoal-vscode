#!/usr/bin/env bash
# WSL bridge: invoke build-and-install.ps1 on the Windows side.
# Does not touch /mnt/* during the build - only resolves the Windows path once.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "This bridge is intended for WSL." >&2
    echo "On native Linux, install @vscode/vsce and run: npx @vscode/vsce package --no-yarn" >&2
    exit 1
fi

PS_SCRIPT="$PROJECT_DIR/build-and-install.ps1"
if [ ! -f "$PS_SCRIPT" ]; then
    echo "ERROR: $PS_SCRIPT not found." >&2
    exit 1
fi

WIN_PROJECT_DIR="$(wslpath -w "$PROJECT_DIR")"
WIN_PS_SCRIPT="$(wslpath -w "$PS_SCRIPT")"

echo "==> Project (WSL):     $PROJECT_DIR"
echo "==> Project (Windows): $WIN_PROJECT_DIR"
echo "==> Script  (Windows): $WIN_PS_SCRIPT"
echo

# -NoProfile: skip user profile (avoids surprises in corporate environments)
# -ExecutionPolicy Bypass: allow running the script without changing the system policy
cmd.exe /c powershell.exe -NoProfile -ExecutionPolicy Bypass \
    -File "$WIN_PS_SCRIPT" -ProjectDir "$WIN_PROJECT_DIR"

echo
echo "==> Done (see output above). Install the .vsix manually in VS Code:"
echo "    Ctrl+Shift+P -> Extensions: Install from VSIX..."