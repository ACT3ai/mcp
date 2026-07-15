# CLAUDE.md — ACT3 MCP Server

Guidance for Claude Code (and humans) working in this repository.

## What this repository is

This is a **public distribution repository**. It carries the **prebuilt
`act3-mcp` binaries** for every supported platform, the installers that select
between them, and the docs. Customers clone it and run `./install.sh` (or
`install.ps1` on Windows).

**There is no source code here, and that is deliberate — not an oversight.**
The server is written in Go and compiled elsewhere; only the compiled output is
published.

## Layout

```
bin/darwin-arm64/act3-mcp        Mac, Apple Silicon
bin/darwin-amd64/act3-mcp        Mac, Intel
bin/linux-amd64/act3-mcp         Linux, x86-64
bin/linux-arm64/act3-mcp         Linux, ARM
bin/windows-amd64/act3-mcp.exe   Windows, x86-64
bin/windows-arm64/act3-mcp.exe   Windows, ARM
install.sh                       macOS/Linux installer
install.ps1                      Windows installer
README.md                        Customer-facing docs
.env.example                     Sample local configuration
```

The binary filename is identical in every directory, so the **directory name**
is what identifies the platform. The installers map `uname -s` / `uname -m` (or
`$env:PROCESSOR_ARCHITECTURE`) onto those directory names.

## Do not build here

There is no build step in this repo and no toolchain to install. If a binary
needs to change, it is rebuilt from the Go source and the resulting binaries are
committed here. A request to "fix the code" in this repo is misdirected — the
change belongs upstream, in the source repo.

## What it is (architecture)

A **local, client-side MCP server** that the MCP client launches over **stdio**:

```
Claude Code ──stdio (JSON-RPC)──▶ act3-mcp ──HTTPS──▶ ACT3 backend
                                     └─ injects auth header
```

- `tools/list` and `tools/call` from the client are **proxied** to the ACT3
  backend with the auth header injected. This is why new tools added on the
  backend appear automatically, with no client update.
- Startup does an `initialize` round-trip, so bad auth or an unreachable backend
  fails fast with a clear message instead of erroring on the first tool call.
- **stdout is the protocol channel.** All logging goes to stderr. Anything else
  printed to stdout corrupts the JSON-RPC stream and breaks the client.

## Authentication

`act3-mcp login` opens the ACT3 dashboard API-keys page; the user pastes a key,
it is verified against the backend, then stored at `~/.act3/credentials.json`
with file mode `0600`.

Resolution order: the `ACT3_API_KEY` environment variable, then stored
credentials. The env var wins, which is what lets CI run without a login.

Never print a key to stdout or include one in an error message.

## Configuration

See the Configuration table in [README.md](./README.md) and the annotated
[.env.example](./.env.example). Every setting is optional; the defaults target
production.

## Because this repo is public

No secrets. No internal hostnames beyond the public API. No proprietary business
logic, prompt text, or reasoning strategy. No internal class, module, or
repository paths. No roadmap of unbuilt work, and above all **nothing describing
a backend limitation or weakness** — that is a map for an attacker.

If you are unsure whether something belongs here, it does not.
