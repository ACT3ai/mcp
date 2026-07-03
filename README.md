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

- Node.js **18+**
- An ACT3 account (<https://app.act3ai.com>)

## Install

```bash
npm install -g @act3ai/mcp
```

Or run without installing:

```bash
npx @act3ai/mcp login
```

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
| `ACT3_API_URL`    | `https://api.act3ai.com`  | Backend base URL (use `http://localhost:3080` for local dev) |
| `ACT3_API_KEY`    | —                         | API key override (skips stored creds; good for CI) |
| `ACT3_CONFIG_DIR` | `~/.act3`                 | Where credentials are stored                |
| `ACT3_LOG_LEVEL`  | `info`                    | `error` \| `warn` \| `info` \| `debug` (logs to stderr) |

## Troubleshooting

- **`Not authenticated`** — run `act3-mcp login` (or set `ACT3_API_KEY`).
- **`ACT3 rejected the credentials (401/403)`** — your key was revoked or is for
  a different environment. Run `act3-mcp login` again.
- **`Cannot reach ACT3 backend`** — check `ACT3_API_URL` and your network.
- **Claude Code shows no tools** — run `act3-mcp status`; it prints the number
  of tools the backend exposes.

## Development

```bash
npm install
npm run build       # compile TypeScript to dist/
npm run typecheck   # type-check only
node dist/index.js status
```

## License

MIT — see [LICENSE](./LICENSE).
