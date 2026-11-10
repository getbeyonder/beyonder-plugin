---
name: beyonder-apps
description: 'This skill should be used when the person asks to read or change something inside one of the company''s apps rather than on the board: "show my deals in AI CRM", "update the deal", "create a post", "move the booking". It covers finding an app''s own tool (apps_tools_list, app_tools_search, app_tool_describe), reading with app_read and changing with app_write.'
user-invocable: false
---

# The apps' own tools

Each app on the board may have its own tools (its MCP). The platform calls them as the person: it signs a short
token for that one app, and the app applies the person's own rights there. Only apps on the board are reachable;
when none of them does the job, `catalog_list` shows apps that can be installed (`app_install`).

## 1. Find the tool

- `apps_tools_list()`: the apps with an MCP and how many tools each has, how many write, how many are kept for a
  person (`human`). `apps_tools_list(app)`: that app's tools, each with a summary, `writes` and `call`.
- `app_tools_search(query, app?)`: at most 10 tools whose name, app title or description holds any of the words (as
  the start of a word), best first. It never searches the catalog.
- `app_tool_describe(app, tool)`: the tool's description and input schema: the arguments to pass as `args`. The app's
  own retry and dry-run arguments are left out: the platform fills them. `description` and `inputSchema` are `null`
  while the app has not described the tool.

Whether a tool reads or writes is what the list says (`writes`, `call`), never guessed from its name. A tool whose
app does not say it only reads counts as a write (`writes: true`, `call: "app_write"`). A tool with `human: true`
(its summary starts with "Person only") answers `needs_human`: do not offer to do it; tell the person to do it in the
app.

## 2. Read with `app_read`

`app_read(app, tool, args)` calls only a tool with `call: "app_read"`; it changes nothing. Args that do not fit the
tool's input schema are refused (`bad_request`, `params.problems` names each field) and nothing is sent: fix them as
`app_tool_describe` shows.

## 3. Change with `app_write`

An app's write changes the person's data. The person's clear request is the yes (AGENT.md): say in one or two plain
sentences what will change, call it, read back. When the request is vague or the change is big (many records, a
delete), dry-run first:

1. `app_write(app, tool, args, dry_run: true)`: the platform's dry run, nothing is written. When the app has its own
   dry run, its preview is in `appPreview`. If `appPreview` asks for more arguments (for example an
   `expectedVersion`), dry-run again with them and show that one.
2. Tell the person in plain words what would change, and wait for their yes.
3. `app_write` again with the same `app`, `tool` and `args` and without `dry_run`. In Claude Code this call may get the
   normal permission prompt (the person may choose "always allow"): a second guard after their yes in chat. If they
   decline, do not try another way.
4. Read back with one of the app's reading tools (`app_read`; `writes: false` in `apps_tools_list(app)`) where the
   app has one, and tell the person what is there now.

When the app runs the work as a job (it answers at once with a job or batch id and a tool to check it), the read after
the start is one read, with or without a dry run: tell the person what was started and how to check it. Check again
only when they ask or after a real pause, never in a loop.

If the app refuses its own dry run (`app_refused` with `params.appPreview`), nothing was written: fix the arguments and
dry-run again. If it refused without a reason or does not accept the platform's token yet (the hint says so), tell the
person and do not retry. `outcome_unknown` after `app_write`: it may have been applied; look with `app_read` first,
never repeat it blindly. A repeat of a write is a new write.

## When the tools are off

Beyonder can switch the apps' tools off for everyone (not per company): then every tool here answers `feature_off`.
Tell the person; do not retry.

Other codes (`no_place`, `role_forbidden`, `module_disabled`, `app_unreachable`, `app_refused`): the
`beyonder-errors` skill.
