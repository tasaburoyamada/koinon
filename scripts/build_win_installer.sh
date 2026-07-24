#!/usr/bin/env bash
# ==============================================================================
# Koinon Standalone LLM Omni-Server - Windows Installer Builder Script
# ==============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${PROJECT_ROOT}/dist"
PKG_DIR="${DIST_DIR}/koinon-windows-v0.1.0"

echo "=================================================="
echo "  Koinon Windows Installer & Package Builder      "
echo "=================================================="
echo "Project Root: ${PROJECT_ROOT}"
echo "Output Directory: ${PKG_DIR}"
echo "=================================================="

# 1. Clean & Prepare Output Directories
rm -rf "${PKG_DIR}" "${DIST_DIR}/koinon-windows-v0.1.0.zip"
mkdir -p "${PKG_DIR}" "${PKG_DIR}/web" "${PKG_DIR}/models" "${PKG_DIR}/doc"

# 2. Build Lean 4 Project Binary
echo "[Step 1/4] Building Koinon Lean 4 Binaries..."
cd "${PROJECT_ROOT}"
lake build

# Copy Binary (Physical or Wrapper fallback)
if [ -f ".lake/build/bin/koinon" ]; then
    cp ".lake/build/bin/koinon" "${PKG_DIR}/koinon"
    echo "✓ Copied koinon binary executable."
fi
if [ -f ".lake/build/bin/koinon.exe" ]; then
    cp ".lake/build/bin/koinon.exe" "${PKG_DIR}/koinon.exe"
    echo "✓ Copied Windows koinon.exe binary."
fi

# 3. Copy Web Assets, Models, and Documentation
echo "[Step 2/4] Copying Assets & Web Studio Files..."
cp -r web/* "${PKG_DIR}/web/"
cp -r installer/* "${PKG_DIR}/"
cp doc/CURRENT_STATUS.md "${PKG_DIR}/doc/" 2>/dev/null || true
cp PROJECT_OVERVIEW.md "${PKG_DIR}/doc/" 2>/dev/null || true

# 4. Packaging Verification & Zip Creation
echo "[Step 3/4] Creating ZIP Distribution Archive..."
cd "${DIST_DIR}"
if command -v zip >/dev/null 2>&1; then
    zip -r "koinon-windows-v0.1.0.zip" "koinon-windows-v0.1.0"
    echo "✓ Created Archive: dist/koinon-windows-v0.1.0.zip"
else
    tar -czf "koinon-windows-v0.1.0.tar.gz" "koinon-windows-v0.1.0"
    echo "✓ Created Archive: dist/koinon-windows-v0.1.0.tar.gz"
fi

# 5. Sanity Test Verification
echo "[Step 4/4] Verifying Package Integrity..."
if [ -f "${PKG_DIR}/koinon-server.bat" ] && [ -f "${PKG_DIR}/install.ps1" ] && [ -f "${PKG_DIR}/koinon_setup.iss" ]; then
    echo "=================================================="
    echo "  SUCCESS: Koinon Windows Installer Package Built! "
    echo "=================================================="
    echo "  Installer Assets Path: ${PKG_DIR}"
    echo "=================================================="
    exit 0
else
    echo "[ERROR] Windows Package Verification Failed!"
    exit 1
fi
