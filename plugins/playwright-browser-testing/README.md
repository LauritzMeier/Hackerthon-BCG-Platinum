# Playwright Browser Testing Plugin

This repo-local Codex plugin exposes the official Playwright MCP server so browser checks can be run against the app during development.

## What It Adds

- a Codex plugin manifest in `.codex-plugin/plugin.json`
- an MCP server definition in `.mcp.json`
- a marketplace entry in `.agents/plugins/marketplace.json`

## MCP Server

The plugin uses the official Playwright MCP server:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

This follows the standard configuration documented by Playwright:

- [Playwright MCP docs](https://playwright.dev/docs/getting-started-mcp)

## Usage

Once the plugin is available in Codex, ask for browser validation directly, for example:

- Open the local web app and smoke test the main flow.
- Verify the compass page renders correctly after this change.
- Test the chatbot to goals flow in the browser.

## Notes

- `npx` and Node.js 18+ need to be available on the machine that runs Codex.
- The Playwright MCP browser runs in headed mode by default, which is useful for interactive debugging.
