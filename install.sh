#!/bin/sh
# ACT3 MCP server — installer for macOS and Linux.
#
# This repo ships one prebuilt binary per platform, under bin/<os>-<arch>/.
# This script picks the one matching your machine and puts it on your PATH.
# There is nothing to compile and no toolchain to install.
#
#   ./install.sh                          install to the default location
#   ACT3_INSTALL_DIR=~/bin ./install.sh   install somewhere specific
#
# Windows: run install.ps1 in PowerShell instead.

set -eu

BINARY="act3-mcp"
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

die() {
    echo "error: $*" >&2
    exit 1
}

# ---- Which platform is this? ------------------------------------------------
# uname's spelling is not Go's spelling, so map both axes explicitly rather than
# guessing. An unrecognized machine gets a clear error, never a wrong binary.
os=$(uname -s)
arch=$(uname -m)

case "$os" in
    Darwin) os="darwin" ;;
    Linux)  os="linux"  ;;
    MINGW*|MSYS*|CYGWIN*)
        die "this is Windows — run install.ps1 in PowerShell instead" ;;
    *)  die "unsupported operating system: $os (supported: macOS, Linux)" ;;
esac

case "$arch" in
    x86_64|amd64)  arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
    *) die "unsupported CPU architecture: $arch (supported: x86_64, arm64)" ;;
esac

src="$repo_dir/bin/$os-$arch/$BINARY"
[ -f "$src" ] || die "no binary for $os-$arch at: $src
       This clone looks incomplete. Try: git pull"

# ---- Where should it go? ----------------------------------------------------
# Prefer an explicit choice, then a system location if we can write to it
# WITHOUT sudo, then a per-user fallback. Never silently escalate privileges.
if [ -n "${ACT3_INSTALL_DIR:-}" ]; then
    dest_dir="$ACT3_INSTALL_DIR"
elif [ -w /usr/local/bin ] 2>/dev/null; then
    dest_dir="/usr/local/bin"
else
    dest_dir="$HOME/.local/bin"
fi

mkdir -p "$dest_dir" || die "cannot create $dest_dir"
[ -w "$dest_dir" ] || die "cannot write to $dest_dir
       Choose another: ACT3_INSTALL_DIR=\$HOME/bin ./install.sh"

dest="$dest_dir/$BINARY"

# ---- Install ----------------------------------------------------------------
# Copy to a temp name in the same directory, then mv into place. A plain cp over
# a running binary can fail with "Text file busy"; an atomic rename cannot.
tmp="$dest.tmp.$$"
trap 'rm -f "$tmp"' EXIT INT TERM
cp "$src" "$tmp"
chmod 0755 "$tmp"
mv -f "$tmp" "$dest"
trap - EXIT INT TERM

# ---- Prove it actually runs -------------------------------------------------
# A copied file is not a working install: the binary could be the wrong arch or
# blocked. Execute it once and fail loudly rather than declare false success.
version=$("$dest" --version 2>/dev/null) || die "installed to $dest, but it will not run.
       This usually means the binary does not match your machine.
       Detected: $os-$arch"

echo "✓ installed $BINARY v$version -> $dest"

# ---- Is it reachable? -------------------------------------------------------
case ":${PATH}:" in
    *":$dest_dir:"*) ;;
    *)
        echo
        echo "NOTE: $dest_dir is not on your PATH, so typing '$BINARY' will not"
        echo "      find it yet. Add this to your ~/.zshrc (or ~/.bashrc):"
        echo
        echo "        export PATH=\"$dest_dir:\$PATH\""
        echo
        echo "      Then open a new terminal."
        ;;
esac

cat <<EOF

Next steps:

  1. Log in to ACT3 (opens the dashboard, then paste your API key):

       $BINARY login

  2. Connect it to Claude Code:

       claude mcp add act3 -- $BINARY serve

  3. Confirm it works:

       $BINARY status

Then just ask Claude Code for the filmmaking change you want.
EOF
