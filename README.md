# ACT3 MCP Server

MCP (Model Context Protocol) server for **ACT3 AI Filmmaking**. It lets Claude
Code — and any other MCP client — drive your ACT3 productions in natural
language: create projects, inspect scenes and shots, edit cast blocking and
cinematography, and regenerate video.

> Ask Claude Code: *"For scenes 3 through 20, if Alex is in the shot and it's an
> exterior, seat him when he isn't speaking and have him running when he is."*
> Claude uses the ACT3 tools to walk the shots and apply the change.

The server runs locally on your machine, authenticates to ACT3 on your behalf,
and proxies tool calls to the ACT3 backend. New capabilities added to ACT3 show
up automatically — no upgrade required.

---

## Requirements

- An ACT3 account (<https://app.act3ai.com>)

That's it. This repo ships **prebuilt binaries** — there is no runtime to
install, nothing to compile, and no Node.js, Python, or Go toolchain needed.

## Install

Clone this repo and run the installer for your platform.

**macOS / Linux**

```bash
git clone https://github.com/ACT3ai/mcp.git
cd mcp
./install.sh
```

**Windows** (PowerShell)

```powershell
git clone https://github.com/ACT3ai/mcp.git
cd mcp
.\install.ps1
```

The installer detects your operating system and CPU, copies the matching binary
onto your PATH, and runs it once to confirm it works.

<details>
<summary>Installing by hand instead</summary>

The binaries live under `bin/`, one directory per platform. Pick the one that
matches your machine and copy it anywhere on your PATH:

| Your machine | Binary |
| --- | --- |
| Mac, Apple Silicon (M1–M4) | `bin/darwin-arm64/act3-mcp` |
| Mac, Intel | `bin/darwin-amd64/act3-mcp` |
| Linux, x86-64 | `bin/linux-amd64/act3-mcp` |
| Linux, ARM | `bin/linux-arm64/act3-mcp` |
| Windows, x86-64 | `bin/windows-amd64/act3-mcp.exe` |
| Windows, ARM | `bin/windows-arm64/act3-mcp.exe` |

Not sure which? On macOS or Linux run `uname -sm`. On Windows, check
`$env:PROCESSOR_ARCHITECTURE`.

The Linux builds are statically linked, so they run on any distribution without
worrying about glibc versions.

</details>

### Where the installer puts it

| Platform | Default location |
| --- | --- |
| macOS / Linux | `/usr/local/bin` if writable, otherwise `~/.local/bin` |
| Windows | `%LOCALAPPDATA%\Programs\act3-mcp` |

Override it with `ACT3_INSTALL_DIR=~/bin ./install.sh`, or
`.\install.ps1 -InstallDir C:\tools\bin`. The installer never asks for `sudo` or
administrator rights; if it can't write to a system directory it falls back to a
per-user one.

## Log in

```bash
act3-mcp login
```

This opens the ACT3 dashboard where you generate an API key, then prompts you to
paste it. The key is verified and stored at `~/.act3/credentials.json` (file
mode `0600`). Check it any time with:

```bash
act3-mcp status
```

## Connect it to Claude Code

Add the server (once):

```bash
claude mcp add act3 -- act3-mcp serve
```

Or add it by hand to `.mcp.json` / your Claude Code config:

```json
{
  "mcpServers": {
    "act3": {
      "command": "act3-mcp",
      "args": ["serve"]
    }
  }
}
```

Then in Claude Code, run `/mcp` to confirm `act3` is connected. That's it — ask
for the filmmaking changes you want.

### Claude Desktop

Same block, added to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "act3": { "command": "act3-mcp", "args": ["serve"] }
  }
}
```

---

## CLI reference

| Command            | What it does                                              |
| ------------------ | -------------------------------------------------------- |
| `act3-mcp serve`   | Run the MCP server on stdio (default; clients launch this)|
| `act3-mcp login`   | Authenticate and store credentials                        |
| `act3-mcp logout`  | Remove stored credentials                                 |
| `act3-mcp status`  | Show auth + backend connectivity and tool count           |
| `act3-mcp help`    | Full help                                                 |

## Configuration

All optional — defaults work for production.

| Variable          | Default                   | Purpose                                     |
| ----------------- | ------------------------- | ------------------------------------------- |
| `ACT3_API_URL`    | `https://api.act3ai.com`  | Backend base URL                            |
| `ACT3_API_KEY`    | —                         | API key override (skips stored creds; good for CI) |
| `ACT3_CONFIG_DIR` | `~/.act3`                 | Where credentials are stored                |
| `ACT3_LOG_LEVEL`  | `info`                    | `error` \| `warn` \| `info` \| `debug` (logs to stderr) |

## Updating

```bash
git pull && ./install.sh
```

## Troubleshooting

- **`act3-mcp: command not found`** — the install directory isn't on your PATH.
  The installer prints the exact line to add to your shell profile; add it and
  open a new terminal.
- **`Not authenticated`** — run `act3-mcp login` (or set `ACT3_API_KEY`).
- **`ACT3 rejected the credentials (401/403)`** — your key was revoked or is for
  a different environment. Run `act3-mcp login` again.
- **`Cannot reach ACT3 backend`** — check `ACT3_API_URL` and your network.
- **Claude Code shows no tools** — run `act3-mcp status`; it prints the number
  of tools the backend exposes.
- **macOS: *"cannot be opened because the developer cannot be verified"*** —
  clear the quarantine flag: `xattr -d com.apple.quarantine $(which act3-mcp)`.
- **Windows: *"running scripts is disabled on this system"*** — allow the
  installer for this session only:
  `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`.

## License

MIT — see [LICENSE](./LICENSE).
