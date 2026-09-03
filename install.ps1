# ACT3 MCP server — installer + first-run setup for Windows.
#
# Picks the prebuilt binary for this machine, puts it on your PATH, then walks
# the first-run steps for you:
#
#   1. Checks whether this machine is already signed in to ACT3. If not, runs
#      `act3-mcp login`, which opens your browser so you can approve this
#      computer. Already signed in? Nothing to do.
#   2. Registers the server with Claude Code (if `claude` is installed and it is
#      not registered yet).
#   3. Runs `act3-mcp status` to prove the whole chain works.
#
#   .\install.ps1                             install to the default location
#   .\install.ps1 -InstallDir C:\tools\bin    install somewhere specific
#   .\install.ps1 -SkipLogin                  install only; do not open a browser
#   .\install.ps1 -SkipClaude                 do not touch Claude Code config
#
# If PowerShell blocks the script, allow it for this session only:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
# macOS/Linux: run install.sh instead.

param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\act3-mcp",
    [switch]$SkipLogin,
    [switch]$SkipClaude
)

$ErrorActionPreference = "Stop"
$binary  = "act3-mcp.exe"
$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Step($msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

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
Step "Installing act3-mcp (windows-$arch)"
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

# ---- Already signed in? -----------------------------------------------------
# `act3-mcp status` exits 0 when credentials exist and work, 1 otherwise. It
# never prints the token. We only trigger a browser login when it says no.
Step "Checking ACT3 sign-in"
if ($SkipLogin) {
    Write-Host "skipped (-SkipLogin) — run 'act3-mcp login' later."
} else {
    # act3-mcp logs to stderr even on success; under ErrorActionPreference=Stop,
    # PowerShell 5.1 turns redirected stderr into a terminating error. Relax it
    # for the silent probes only.
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    & $dest status *> $null
    $signedIn = ($LASTEXITCODE -eq 0)
    $account = ""
    if ($signedIn) {
        $authLine = & $dest status 2>$null | Select-String '^Auth:\s*(\S+)'
        if ($authLine) { $account = " as $($authLine.Matches[0].Groups[1].Value)" }
    }
    $ErrorActionPreference = $prevEAP
    if ($signedIn) {
        Write-Host "OK already signed in$account — no login needed." -ForegroundColor Green
    } else {
        Write-Host "Not signed in. Opening your browser to approve this computer..."
        Write-Host "(You must already be signed in to ACT3 in that browser.)"
        Write-Host ""
        & $dest login
        if ($LASTEXITCODE -ne 0) {
            throw "Login did not complete.`n       Run it again any time:  act3-mcp login`n       No browser on this machine?  act3-mcp login --api-key"
        }
    }
}

# ---- Register with Claude Code ---------------------------------------------
Step "Connecting to Claude Code"
if ($SkipClaude) {
    Write-Host "skipped (-SkipClaude)."
} elseif (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "Claude Code CLI ('claude') not found — skipping. When you have it, run:"
    Write-Host "    claude mcp add act3 -s user -- `"$dest`" serve"
} else {
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    claude mcp get act3 *> $null
    $registered = ($LASTEXITCODE -eq 0)
    $ErrorActionPreference = $prevEAP
    if ($registered) {
        Write-Host "OK 'act3' is already registered with Claude Code — leaving it as is." -ForegroundColor Green
        Write-Host "  (To re-register: claude mcp remove act3, then re-run this script.)"
    } else {
        # -s user: register for the whole account, not just the directory this
        # script happens to run from. Absolute path: works even when InstallDir
        # is not on the PATH Claude Code launches servers with.
        claude mcp add act3 -s user -- $dest serve
        if ($LASTEXITCODE -eq 0) {
            Write-Host "OK registered 'act3' with Claude Code (all projects)" -ForegroundColor Green
        } else {
            Write-Host "could not register with Claude Code — run by hand:"
            Write-Host "    claude mcp add act3 -s user -- `"$dest`" serve"
        }
    }
}

# ---- Prove the whole chain works -------------------------------------------
Step "Final check"
if ($SkipLogin) {
    Write-Host "(skipped — not signed in yet)"
} else {
    & $dest status
    if ($LASTEXITCODE -ne 0) {
        throw "Status check failed — see the message above."
    }
}

# ---- Wrap up ----------------------------------------------------------------
Write-Host @"

Done. In Claude Code, run /mcp to confirm 'act3' is connected, then ask for the
filmmaking change you want.
"@
