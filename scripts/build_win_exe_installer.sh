#!/usr/bin/env bash
# ==============================================================================
# Koinon Standalone LLM Omni-Server - Windows Standard Exe Installer Builder
# Compiles installer/koinon_setup.nsi using makensis into a single setup EXE.
# ==============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${PROJECT_ROOT}/dist"
EXE_OUT="${DIST_DIR}/Koinon_OmniServer_Setup_v0.1.0.exe"

echo "=================================================="
echo "  Koinon Windows Exe Installer Generator (NSIS)   "
echo "=================================================="

# 1. First ensure base Windows package folder is ready
bash "${PROJECT_ROOT}/scripts/build_win_installer.sh"

# 2. Compile NSIS Setup Script into Windows .exe Installer
echo "[Step 2/2] Compiling NSIS script into standalone Windows Setup Exe..."
cd "${PROJECT_ROOT}/installer"

if command -v makensis >/dev/null 2>&1; then
    makensis koinon_setup.nsi
    echo "✓ Successfully compiled NSIS setup script."
else
    echo "[ERROR] makensis tool not found!"
    exit 1
fi

# 3. Verify .exe output file
if [ -f "${EXE_OUT}" ]; then
    EXE_SIZE=$(du -h "${EXE_OUT}" | cut -f1)
    echo "=================================================="
    echo "  SUCCESS: Windows Setup Exe Built Successfully!  "
    echo "=================================================="
    echo "  Exe File Path: ${EXE_OUT}"
    echo "  Exe File Size: ${EXE_SIZE}"
    echo "=================================================="
    exit 0
else
    echo "[ERROR] Exe setup file generation failed!"
    exit 1
fi
