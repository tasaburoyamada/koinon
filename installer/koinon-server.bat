@echo off
title Koinon Standalone LLM Omni-Server v0.1
color 0A

echo ==================================================
echo   Koinon Standalone LLM Omni-Server v0.1.0-alpha
echo ==================================================
echo   Starting Windows Socket HTTP Listener on Port 8080...
echo   Open Web Browser at: http://localhost:8080/
echo ==================================================

if exist "koinon.exe" (
    koinon.exe --server-daemon --port 8080
) else if exist "bin\koinon.exe" (
    bin\koinon.exe --server-daemon --port 8080
) else (
    echo [NOTICE] Binary 'koinon.exe' not found. Starting in simulation fallback mode.
    pause
)
