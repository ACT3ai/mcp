#!/bin/sh
# ACT3 MCP server — installer + first-run setup for macOS and Linux (v2).
#
# Does everything install.sh does (pick the prebuilt binary for this machine and
# put it on your PATH), then walks the first-run steps for you:
#
#   1. Checks whether this machine is already signed in to ACT3 (production).
#      If not, runs `act3-mcp login --mode production`, which opens your browser
#      so you can approve this computer. Already signed in? Nothing to do.
#   2. Registers the server with Claude Code (if `claude` is installed and it is
#      not registered yet).
#   3. Runs `act3-mcp status --mode production` to prove the whole chain works.
#
#   ./installV2.sh                          install to the default location
#   ACT3_INSTALL_DIR=~/bin ./installV2.sh   install somewhere specific
#   ACT3_SKIP_LOGIN=1 ./installV2.sh        install only; do not open a browser
#   ACT3_SKIP_CLAUDE=1 ./installV2.sh       do not touch Claude Code config
#
# Windows: run install.ps1 in PowerShell instead.

set -eu

BINARY="act3-mcp"
MODE="production"
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

die() {
    echo "error: $*" >&2
    exit 1
}
step() {
    echo
    echo "==> $*"
}

# ---- Which platform is this? ------------------------------------------------
os=$(uname -s)
arch=$(uname -m)

case "$os" in
    Darwin) os="mac" ;;
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

case "$os-$arch" in
    mac-arm64)   platform="Mac-Apple_Silicon" ;;
    mac-amd64)   platform="Mac-Intel_CPU" ;;
    linux-amd64) platform="linux-amd64" ;;
    linux-arm64) platform="linux-arm64" ;;
    *) die "unsupported machine: $os-$arch" ;;
esac

src="$repo_dir/bin/$platform/$BINARY"
[ -f "$src" ] || die "no binary for $platform at: $src
       This clone looks incomplete. Try: git pull"

# ---- Where should it go? ----------------------------------------------------
if [ -n "${ACT3_INSTALL_DIR:-}" ]; then
    dest_dir="$ACT3_INSTALL_DIR"
elif [ -w /usr/local/bin ] 2>/dev/null; then
    dest_dir="/usr/local/bin"
else
    dest_dir="$HOME/.local/bin"
fi

mkdir -p "$dest_dir" || die "cannot create $dest_dir"
[ -w "$dest_dir" ] || die "cannot write to $dest_dir
       Choose another: ACT3_INSTALL_DIR=\$HOME/bin ./installV2.sh"

dest="$dest_dir/$BINARY"

# ---- Install ----------------------------------------------------------------
step "Installing $BINARY ($platform)"
tmp="$dest.tmp.$$"
trap 'rm -f "$tmp"' EXIT INT TERM
cp "$src" "$tmp"
chmod 0755 "$tmp"
mv -f "$tmp" "$dest"
trap - EXIT INT TERM

version=$("$dest" --version 2>/dev/null) || die "installed to $dest, but it will not run.
       This usually means the binary does not match your machine.
       Detected: $platform"
echo "✓ installed $BINARY v$version -> $dest"

# Make the rest of this script (and the `claude mcp add` we register) work even
# if dest_dir is not on PATH yet.
path_note=""
case ":${PATH}:" in
    *":$dest_dir:"*) ;;
    *)
        PATH="$dest_dir:$PATH"; export PATH
        path_note="$dest_dir is not on your PATH. Add this to ~/.zshrc (or ~/.bashrc), then open a new terminal:

        export PATH=\"$dest_dir:\$PATH\""
        ;;
esac

# ---- Already signed in? -----------------------------------------------------
# `act3-mcp status` exits 0 when credentials exist and work, 1 otherwise. It
# never prints the token. We only trigger a browser login when it says no.
step "Checking ACT3 sign-in ($MODE)"
if [ "${ACT3_SKIP_LOGIN:-}" = "1" ]; then
    echo "skipped (ACT3_SKIP_LOGIN=1) — run '$BINARY login --mode $MODE' later."
elif "$dest" status --mode "$MODE" >/dev/null 2>&1; then
    account=$("$dest" status --mode "$MODE" 2>/dev/null | sed -n 's/^Auth:[[:space:]]*\([^ ]*\).*/\1/p')
    echo "✓ already signed in${account:+ as $account} — no login needed."
else
    echo "Not signed in. Opening your browser to approve this computer…"
    echo "(You must already be signed in to ACT3 in that browser.)"
    echo
    "$dest" login --mode "$MODE" || die "login did not complete.
       Run it again any time:  $BINARY login --mode $MODE
       No browser on this machine?  $BINARY login --mode $MODE --api-key"
fi

# ---- Register with Claude Code ---------------------------------------------
step "Connecting to Claude Code"
if [ "${ACT3_SKIP_CLAUDE:-}" = "1" ]; then
    echo "skipped (ACT3_SKIP_CLAUDE=1)."
elif ! command -v claude >/dev/null 2>&1; then
    echo "Claude Code CLI ('claude') not found — skipping. When you have it, run:"
    echo "    claude mcp add act3 -e ACT3_MODE=$MODE -- $BINARY serve"
elif claude mcp get act3 >/dev/null 2>&1; then
    echo "✓ 'act3' is already registered with Claude Code — leaving it as is."
    echo "  (To re-register: claude mcp remove act3 -s local, then re-run this script.)"
else
    claude mcp add act3 -e "ACT3_MODE=$MODE" -- "$BINARY" serve \
        && echo "✓ registered 'act3' with Claude Code" \
        || echo "could not register with Claude Code — run by hand:
    claude mcp add act3 -e ACT3_MODE=$MODE -- $BINARY serve"
fi

# ---- Prove the whole chain works -------------------------------------------
step "Final check"
if [ "${ACT3_SKIP_LOGIN:-}" = "1" ]; then
    echo "(skipped — not signed in yet)"
else
    "$dest" status --mode "$MODE" || die "status check failed — see the message above."
fi

# ---- Wrap up ----------------------------------------------------------------
echo
if [ -n "$path_note" ]; then
    echo "NOTE: $path_note"
    echo
fi
cat <<MSG
Done. In Claude Code, run /mcp to confirm 'act3' is connected, then ask for the
filmmaking change you want.

Tip: this build needs '--mode $MODE' (or ACT3_MODE=$MODE) for login/status.
     Set it once:  echo 'export ACT3_MODE=$MODE' >> ~/.zshrc
MSG
