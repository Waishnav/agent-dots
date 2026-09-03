---
name: chrome-devtools-pi
description: Browser QA and debugging on the user's Chromium via chrome-devtools-mcp through pi-mcp-adapter. Use for verifying UI changes, console/network errors, form flows, screenshots, and performance traces. Requires remote debugging enabled in Chromium (chrome://inspect/#remote-debugging).
---

# Chrome DevTools via Pi MCP

Pi uses **pi-mcp-adapter** (installed). MCP servers are **lazy** — they connect on first tool use.

## Before first use (running Chromium)

1. In Chromium, open `chrome://inspect/#remote-debugging` and enable remote debugging.
2. When the agent first drives the browser, click **Allow** on the permission dialog.

To attach via a fixed port instead of auto-connect, edit `~/.pi/agent/mcp.json` and replace `--autoConnect` with `--browser-url=http://127.0.0.1:9222`, then restart Chromium with `--remote-debugging-port=9222` and a separate `--user-data-dir`.

## Discover and call tools

Do **not** assume tool names are in context. Use the proxy:

```
mcp({ search: "navigate" })
mcp({ search: "screenshot" })
mcp({ search: "performance" })
```

Then invoke ( **`args` is a JSON string** ):

```
mcp({ tool: "chrome_devtools_navigate_page", args: '{"url":"http://localhost:8081"}' })
```

Use `mcp({ search: "..." })` to get the exact prefixed tool name.

## Pi slash commands

After restart: `/mcp` to inspect servers and connection status.

## Paseo web QA

- Dev URL: `http://localhost:8081` (`npm run dev:app`).
- Do **not** use browser back/forward — navigate by full URL or UI clicks.

## Performance audits

Use the **web-perf** skill with the same MCP server.

## Security

Disable remote debugging when done; avoid sensitive sites while connected.
