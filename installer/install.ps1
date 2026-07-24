# Koinon Standalone LLM Omni-Server - PowerShell Windows Auto-Installer
param (
    [string]$InstallPath = "$env:LocalAppData\Koinon"
)

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Koinon Omni-Server Windows PowerShell Installer " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Target Installation Path: $InstallPath" -ForegroundColor Yellow

# 1. Create Target Directory
if (!(Test-Path -Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    Write-Host "✓ Created installation directory: $InstallPath" -ForegroundColor Green
}

# 2. Copy Package Files
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "Copying application files from $ScriptDir..." -ForegroundColor Yellow

Copy-Item -Path "$ScriptDir\*" -Destination $InstallPath -Recurse -Force
Write-Host "✓ Copied core assets, web UI, and configuration files." -ForegroundColor Green

# 3. Create Desktop & Start Menu Shortcuts
$WScriptShell = New-Object -ComObject WScript.Shell
$DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$ShortcutPath = Join-Path -Path $DesktopPath -ChildPath "Koinon Omni-Server.lnk"

$Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = Join-Path -Path $InstallPath -ChildPath "koinon-server.bat"
$Shortcut.WorkingDirectory = $InstallPath
$Shortcut.Description = "Koinon Standalone LLM Omni-Server"
$Shortcut.Save()

Write-Host "✓ Desktop Shortcut created: $ShortcutPath" -ForegroundColor Green

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Koinon Omni-Server Installation Complete!       " -ForegroundColor Green
Write-Host "  Launch using Desktop Shortcut or koinon-server.bat" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan
