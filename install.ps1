# ACT3 MCP server — installer for Windows.
#
# This repo ships one prebuilt binary per platform, under bin\<os>-<arch>\.
# This script picks the one matching your machine and puts it on your PATH.
# There is nothing to compile and no toolchain to install.
#
#   .\install.ps1                             install to the default location
#   .\install.ps1 -InstallDir C:\tools\bin    install somewhere specific
#
# If PowerShell blocks the script, allow it for this session only:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\act3-mcp"
)

$ErrorActionPreference = "Stop"
$binary  = "act3-mcp.exe"
$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---- Which architecture is this? --------------------------------------------
# Map Windows' spelling onto Go's explicitly; an unknown machine gets a clear
# error rather than a wrong binary.
$arch = switch ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64" { "amd64" }
    "ARM64" { "arm64" }
    "x86"   { throw "32-bit Windows is not supported (need 64-bit x64 or ARM64)." }
    default { throw "Unsupported CPU architecture: $($env:PROCESSOR_ARCHITECTURE)" }
}

$src = Join-Path $repoDir "bin\windows-$arch\$binary"
if (-not (Test-Path $src)) {
    throw "No binary for windows-$arch at: $src`n       This clone looks incomplete. Try: git pull"
}

# ---- Install ----------------------------------------------------------------
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$dest = Join-Path $InstallDir $binary

# Windows locks a running .exe, so a copy over it fails. Say so usefully.
try {
    Copy-Item -Path $src -Destination $dest -Force
} catch {
    throw "Could not write $dest`n       If act3-mcp is running (or Claude Code is open), close it and retry."
}

# ---- Prove it actually runs -------------------------------------------------
# A copied file is not a working install. Execute it once and fail loudly.
try {
    $version = (& $dest --version 2>$null | Out-String).Trim()
} catch {
    $version = ""
}
if (-not $version) {
    throw "Installed to $dest, but it will not run.`n       This usually means the binary does not match your machine (detected: windows-$arch)."
}

Write-Host "OK installed act3-mcp v$version -> $dest" -ForegroundColor Green

# ---- Is it reachable? -------------------------------------------------------
# Persist to the USER PATH (not machine) so no admin rights are needed. The
# current session's PATH is separate, so update both or the next command fails.
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$InstallDir", "User")
    Write-Host "Added $InstallDir to your user PATH (new terminals will see it)."
}
if ($env:Path -notlike "*$InstallDir*") {
    $env:Path = "$env:Path;$InstallDir"
}

Write-Host @"

Next steps:

  1. Log in to ACT3 (opens the dashboard, then paste your API key):

       act3-mcp login

  2. Connect it to Claude Code:

       claude mcp add act3 -- act3-mcp serve

  3. Confirm it works:

       act3-mcp status

Then just ask Claude Code for the filmmaking change you want.
"@
