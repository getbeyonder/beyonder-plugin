---
name: beyonder-board
description: 'This skill should be used when the person asks to change a company''s Beyonder board: "install AI CRM", "add Booking", "install an app", "install the suite", "install the template", "pause the app", "archive Hitmaker", "remove the app", or "how do I set up my board". It covers the write tools app_install, suite_install, connect, link_pause, link_resume, app_pause, app_resume, app_archive and app_remove, step by step and safely, and a whole suite only after a dry run and an explicit yes.'
user-invocable: false
---

# Building and changing a board

The write tools act as the signed-in person, with exactly their rights, and change the board at once when called
without `dry_run`. With `dry_run: true` they change nothing and say what would change.

## Two kinds of change

The agent file (AGENT.md) says when to act at once and when to dry-run and wait for a yes:

- Creating or reversible: `app_install`, `suite_install`, `connect`, `link_pause`, `link_resume`, `app_pause`,
  `app_resume`. Dry-run first when the request is vague or the change is big. A whole suite always gets a dry run
  and the person's explicit yes, even when they named it.
- Takes something away: `app_archive`, `app_remove` (a change inside an app, `app_write`: see `beyonder-apps`). Always
  dry-run first, explain what would be lost and what is kept, and ask for a yes in chat; make the real call only after
  that yes, even when they asked for it clearly. In Claude Code the plugin's hook then shows an approval prompt for the
  real call: a second guard, not the yes. If they decline either, do not try another way.

## Steps

1. **Read first.** `list_apps(company)` shows the apps, their state and deployment, the links and the proposed ones,
   and the person's rights. `catalog_list` shows the ready-made apps that can be installed (never guess an app id),
   `suite_get` a suite (its apps by id: name them by their `catalog_list` titles), `link_status` one link.
   `company` may be left out when the person has only one.
2. **Dry run** when the list above says so. Tell the person in plain words what would happen (which app, which
   link, what stops, what is kept), not the raw JSON. When you offered options (a suite or single apps), a yes that
   does not pick one of them is not a choice: ask again which one.
3. **Write.** The same tool and arguments without `dry_run`.
4. **Read back.** `list_apps` (or `suite_get`, `link_status`) and tell the person what is there now.

"... already ...; nothing to do" is a fine answer: nothing was written and there is nothing to repeat.
`outcome_unknown`: the write may have been applied. Read the state and never repeat it blindly. Other answers and
refusals: the `beyonder-errors` skill.

## Installing

- The `app_install` dry run shows `appsOnBoard` and `appsAfter`.
- After the install the app may wait for its deployment or for the company owner's approval: the answer has
  `needs_owner: true` and a `link` to the company's board (`/board/c/<cell>`). Tell the person the owner approves it
  there; an agent may not. For `approval: started` the platform started the approval itself, but it can still be
  refused: if `list_apps` still shows the app `planned`, the owner presses Approve at that link.
- `app_install` connects nothing. Do not `connect` the new app until `list_apps` shows it ready; then use `connect`
  (the `beyonder-links` skill).
- An app taken off the board before is in the board's `archived` list (`app_restore` without `app` lists them too).
  It comes back as the agent file (AGENT.md) says: ask with `ask_choice`, then `app_restore(app, mode: "data")` (the
  same project and its data come back) or `mode: "app"` (a new, empty project; the old data never comes back). An
  `app_install` or `suite_install` without `data` for such an app is refused with `bad_request`: that is the question.
- `suite_install` installs every app of the suite not on the board yet and the platform turns on the links the suite
  defines. It runs for minutes: follow it with `suite_get` (per app: `queued`, `getting_ready`, `needs_owner`,
  `present`, `failed`, `refused`). Apps not bought are refused by the platform; the rest installs. The platform
  switches on the suite's links when the run is done: do not connect them by hand. A template also gets its starter
  settings from the platform once its apps are ready: there is no extra step. A part that waits for something first
  (such as a connected channel) is added later by the platform by itself.

## Pause, resume, archive, remove

| Tool | What happens |
|---|---|
| `link_pause` / `link_resume` | The data of one link is held: nothing passes, nothing is deleted; what the source gathers passes on resume |
| `app_pause` / `app_resume` | The app stops serving, its links wait, its data stays |
| `app_archive` | The app stops; its data is exported and kept 12 months (the answer's `export`) |
| `app_remove` | The app leaves the board; a ready-made app's project is archived and its data kept; its links leave the board. The dry run is the platform's own removal report and the links taken off |

Permanent deletion is not offered.
