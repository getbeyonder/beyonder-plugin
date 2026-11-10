# Beyonder for Claude Code and Codex

The `beyonder` plugin lets you run your company's [Beyonder](https://beyonder.si) board from Claude Code or Codex, as yourself
and with exactly your rights: see the board, install apps and suites from the catalog, connect, pause and resume
apps and the links between them, and use each app's own tools ("show my deals in AI CRM", "add Booking").

What it brings:

- the Beyonder MCP server (you sign in with your Beyonder account);
- skills that teach Claude how to work with a board, its apps, links and errors;
- an approval step: removing or archiving an app always asks you first, even if you once chose "always allow".
  Previews (dry runs) change nothing and need no approval; other changes follow your normal Claude Code permissions.

## Requirements

- Claude Code 2.1.295 or later (`claude --version`).
- On Windows: [Git for Windows](https://git-scm.com/downloads/win) (Git Bash), since the plugin's hooks run `sh`.

## Install

In Claude Code:

```
/plugin marketplace add getbeyonder/beyonder-plugin
/plugin install beyonder@beyonder
```

The plugin is `beyonder` (shown as "Beyonder") in the marketplace `beyonder`.

## Sign in

Start a new session and open `/mcp`. The `beyonder` server says it needs authentication: choose it, sign in with
Beyonder in the browser that opens, and come back. Then ask "show my board": Claude reads it and lists your apps.
Nothing is changed.

## Update

Auto-update is off by default for third-party marketplaces such as this one. To turn it on: `/plugin`, then
**Marketplaces**, choose `beyonder`, then **Enable auto-update**.

To update by hand:

```
/plugin marketplace update beyonder
/reload-plugins
```

## Codex

The same plugin works in OpenAI Codex (Codex CLI 0.167.0 or later). In a terminal:

```
codex plugin marketplace add getbeyonder/beyonder-plugin
codex plugin add beyonder@beyonder
codex mcp login beyonder
```

The last command opens the browser to sign in with Beyonder. Then start Codex and ask "show my board". Through the
Beyonder tools, Codex asks you before every remove, archive or restore of an app and before every write inside an
app, previews included. The plugin also brings a hook for Codex that stops the command line from removing or
archiving an app without that question; Codex runs it only after you trust it in `/hooks`.

## Command line (optional)

When the MCP tools are not available in a session, Claude may offer to install the `beyonder` command line from the
Beyonder server. It shows you the exact command and runs it only after you agree.

## Data

- The plugin's hooks run on your computer and send nothing anywhere: one adds the plugin's instructions to the session,
  the other asks you before an app is removed or archived.
- The plugin talks only to the Beyonder MCP server, `https://mcp.beyonder.si/mcp`, signed in as you.
- The command line installer comes from the same server and runs only after you agree. Before installing, it checks
  the download's sha256 (with `sha256sum`, `shasum` or `openssl`; it says so when none of them is there).
- `beyonder upload` sends only the file named in the command, and Claude is told to upload only a file you named.

## Support

[beyonder.si](https://beyonder.si)

Privacy: [beyonder.si/privacy](https://beyonder.si/privacy). Terms: [beyonder.si/terms](https://beyonder.si/terms).

## License

Apache License 2.0. See
[LICENSE](https://github.com/getbeyonder/beyonder-plugin/blob/main/LICENSE).
