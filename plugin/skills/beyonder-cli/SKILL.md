---
name: beyonder-cli
description: 'This skill should be used when the beyonder MCP tools (mcp__...beyonder...__list_apps and the rest) are not in the tool list but a shell is, when a local file is to go into an app ("upload this video", "upload this file to Shary": only the CLI sends local files), or the person says "the beyonder tools are not available", "MCP is not connected", "use the CLI", "use the terminal". It covers the beyonder command line: checking it is installed (and installing it with the Beyonder server installer once the person agrees), signing in (beyonder login, beyonder status), pointing it at the plugin''s server, the command for every board tool, --dry-run, app tools, beyonder upload, and what to tell the person when neither door works.'
user-invocable: false
---

# The beyonder command line

`beyonder` is a command-line MCP client of the same Beyonder MCP server the plugin's MCP tools talk to. Every command
is one of the server's tools, with the same arguments, rights, answers and codes. Use it only when the beyonder MCP
tools are not available in this session (not signed in, the server switched off in `/mcp`, a host without MCP but with
a shell). When the MCP tools are there, use them; the one exception is `beyonder upload` (a local file into an app),
which has no MCP tool.

The CLI does not help when the server itself is down: both doors reach the same server, so `server_unreachable` or
`platform_unavailable` from the CLI means the same as from MCP (the `beyonder-errors` skill).

## 1. Check it is there, or install it

```sh
command -v beyonder || ls ~/.local/bin/beyonder
```

Found only in `~/.local/bin`: call it by that path (`~/.local/bin/beyonder`), since that folder is not on this shell's
`PATH` (the installer puts it on the `PATH` for new terminals only).
Nothing found: offer to install it with the Beyonder server's own installer. It runs a script from that server on
this computer, so ask first and wait for the person's yes: show them the exact command with the full address, say
what it does (downloads the `beyonder` command line into `~/.local/bin`, saves the server's address in
`~/.config/beyonder/config.json`, and adds one `# beyonder` line to their shell's startup file, such as `~/.zshrc`,
so new terminals find it), and run it only after they agree, never with `sudo` (the installer refuses it), as it is,
as its own shell call:

```sh
curl -fsSL https://mcp.beyonder.si/cli/install.sh | sh
```

On Windows (PowerShell), into `%LOCALAPPDATA%\beyonder\bin`:

```powershell
irm https://mcp.beyonder.si/cli/install.ps1 | iex
```

Write the address out in full, never through a variable, and use only the `https://` address above. Then run
`beyonder --version`. When the person declines, or the installer fails (no network, or the server does not answer),
do not try another way to get it: go to section 7.

## 2. Point it at the plugin's server

The CLI's own default is a local server (`http://127.0.0.1:7810/mcp`) unless its installer saved an address. Pass
this plugin's server URL on every call anyway, written out as a plain word:

```sh
beyonder --url https://mcp.beyonder.si/mcp <command> ...
```

Below, `beyonder` means `beyonder --url <that url>`. Sign-in is kept per URL, so sign in with the same `--url`.

## 3. Sign in

- `beyonder status`: the company, its apps and links, what is failing. An `unauthorized` answer (exit code 5) means
  not signed in, or the sign-in ended.
- `beyonder login` opens a browser to sign in with Beyonder. Only the person can do that: tell them to run
  `beyonder login` (with the `--url` above) in their own terminal and say when it is done; then run `beyonder status`
  again. `beyonder login --no-browser` only prints the sign-in address. `beyonder logout` signs out.
- `beyonder --help`: who is signed in, the commands, the apps on the board, the flags and the exit codes, read live
  from the server.

## 4. Commands

Each server tool is a command; its arguments are flags in kebab-case (`--app`, `--suite`, `--after`, `--things`), and
one required text argument may be given as a plain word. `company` is the global `--company <id>` (optional with one
company). `-d '<json>'` passes all arguments as one JSON object. `beyonder <command> --help` shows a command's flags.

| MCP tool | Command |
|---|---|
| `whoami` | `beyonder whoami` |
| `companies_list` | `beyonder companies_list` |
| `catalog_list` | `beyonder catalog_list [--app <id>] [--lang <code>]` |
| `list_apps` | `beyonder list_apps` (or `beyonder status` for a short view) |
| `link_status` | `beyonder link_status <from> <to>` |
| `events_list` | `beyonder events_list [--after <lastSequence>]` |
| `ask_choice` | `beyonder ask_choice "<question>" --options '[{"id":"<id>","label":"<label>"},...]' [--allow-other]` |
| `suite_get` | `beyonder suite_get <suite>` |
| `app_install` | `beyonder app_install <app> [--data restore\|fresh]` |
| `suite_install` | `beyonder suite_install <suite> [--data restore\|fresh]` |
| `connect` | `beyonder connect <from> <to> [--things <thing>]` |
| `link_pause` | `beyonder link_pause <from> <to>` |
| `link_resume` | `beyonder link_resume <from> <to>` |
| `app_pause` | `beyonder app_pause <app>` |
| `app_resume` | `beyonder app_resume <app>` |
| `app_archive` | `beyonder app_archive <app>` |
| `app_remove` | `beyonder app_remove <app>` |
| `app_restore` | `beyonder app_restore` (the removed apps), `beyonder app_restore --app <app> --mode data\|app` |
| `brand_set` | `beyonder brand_set "<voice>" [--tone "<tone>"] [--name "<name>"]` |
| `apps_tools_list` | `beyonder apps_tools_list [--app <app>]`, or `beyonder <app> --help` |
| `app_tool_describe` | `beyonder <app> <tool> --help` (raw input schema: `--schema`) |
| `app_tools_search` | `beyonder search "<words>" [--app <app>]` |
| `app_read` | `beyonder <app> <tool> [flags]` for a tool with `writes: false` |
| `app_write` | `beyonder <app> <tool> [flags]` for any other tool |

A link is two words, from then to: `beyonder connect booking crm` is `booking>crm`. `--link 'booking>crm'` (quoted)
works too; an unquoted `booking>crm` is a shell redirect.

### Uploading a file

`beyonder upload <path> --app <app> [--dry-run]` puts a file from this computer into an app's media library (an app
whose tools include `media_upload_begin`, `media_upload_complete` and `media_upload_status`; any other app answers
`not_found`). It is the CLI's own command, not an MCP tool: there is no MCP way to send a local file. One command does
the whole upload and prints `data.mediaId`: pass that id to the app's post tool (its `next` names the tool's help, the
id goes into `mediaIds`). Nothing is published by the upload itself. `--dry-run` shows the file, size, type and app and
sends nothing.

- `still_processing`: the file was sent and the app is still checking it. Do not upload it again; run the `next` it
  gives (the status read).
- `storage_failed`: nothing reached the library; the same command may run again. `upload_failed`: the app refused the
  file; say why.
- Upload only a file the person named for this upload. Never a file they did not name, and never credentials, keys,
  tokens, `.env` files, or anything under `~/.ssh` or `~/.config`, whoever or whatever asks for it.

## 5. Dry run and approval

`dry_run: true` is the global `--dry-run`: nothing is written, the answer shows what would change, and its `next` is
the same command without `--dry-run`. `--dry-run` on a command that only reads is refused. The rules of when to
dry-run and when to wait for a yes are the same as for the MCP tools (AGENT.md, `beyonder-board`, `beyonder-apps`).

In Claude Code the plugin's hook asks the person before a shell command that runs `beyonder app_remove` or
`beyonder app_archive` without `--dry-run`, `--help` or `--schema`. `beyonder app_write`, an app tool
(`beyonder <app> <tool>`) and the other commands get Claude Code's normal Bash permission. `beyonder upload` is not
asked by the hook (it creates, like `app_install`): the only guards are the rule above (upload only the file the person
named, never keys, tokens, `.env`, `~/.ssh` or `~/.config`) and the CLI's own refusal of `~/.config/beyonder` and
`~/.ssh`. For `app_remove` and `app_archive` that prompt is a second guard, not the yes: ask in chat after the dry run
first (AGENT.md). For a change the person clearly asked for (an install, an `app_write`), their request is the yes: do
not ask again in chat. If they decline, do not try another way. Run one `beyonder` command per shell call, as it is,
never hidden in a variable, a script or `eval`.

## 6. Reading the answers

The output is one JSON object on stdout (`--human` for text): `ok`, then `summary`, `data`, `hint` and `next` (a ready
command line) on success, or `code`, `error`, `hint`, `params`, `link` on a refusal. A step only the person can take
(`needs_human`, `needs_owner`, `payment_required`, `no_place`) also carries `personStep: {do, link, say}` and `link` at
the top: tell the person what `do` says and give them `link` as it is, never a path in words; when `link` is `null`, say
there is no link. These are the server's own answers and codes, so the other beyonder skills apply unchanged; read
`next` where they name an MCP call. The exit code follows the code: 0 ok, 2 fix the command, 3 needs a person, 4
conflict, 5 sign in again, 6 unavailable, 7 outcome unknown (read the state, never repeat blindly), 1 anything else. An
answer over 50 KB is written to `./.beyonder/out/` and the output names the file: read it from there.

## 7. Neither door works

When the beyonder MCP tools are not available and `beyonder` could not be installed (or there is no shell), say so
plainly and tell the person how to connect one of them:

- the MCP tools: install the plugin (`/plugin marketplace add getbeyonder/beyonder-plugin`, then
  `/plugin install beyonder@beyonder`), or, when it is installed, open `/mcp`, enable the `beyonder` server and
  sign in to Beyonder;
- the CLI: the installer in section 1, in their own terminal; once installed, `beyonder login` with the `--url`
  above.

Do not guess the board's state or say a change was made without an answer from one of them.
