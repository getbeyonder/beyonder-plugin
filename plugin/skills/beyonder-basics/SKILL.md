---
name: beyonder-basics
description: 'This skill should be used when the person asks what Beyonder is or what one of its words means ("what is a board", "what is a suite", "what is a template", "what does archive mean", "what is a link"), asks who may do what ("can I change the board", "why am I not allowed", "what are my rights"), or when a beyonder tool answer uses a term (company or cell, ready-made app, catalog, suite, template, gives and takes, owner approval, role) that needs explaining.'
user-invocable: false
---

# Beyonder in short

Beyonder is a platform where each company has a **board**: the ready-made apps it installed and the links between
them. The beyonder MCP tools act on the board as the signed-in person, with exactly their rights.

## Glossary

| Word | Meaning |
|---|---|
| Company (cell) | One company on Beyonder. The tools call it `company`: its cell id, slug or name. The answers carry the cell id; pass that id on later calls. `companies_list` lists them; `company` may be left out when the person has only one. Archived companies are never picked |
| Board | The company's apps and the links between them. `list_apps` reads it |
| Ready-made app | An app from the catalog (AI CRM, Booking, Hitmaker and others), installed on the board with `app_install`. On the board it has an `id` (used in link keys), a `title`, a `state` and a `deployment` (`planned`, `bound` = ready, `paused`, ...), and an `url` once it serves |
| Catalog | The ready-made apps that can be installed: `catalog_list`, with the company's access in words (all apps by subscription, only the bought ones, or a plan is needed). `catalog_list(app)` gives one app's whole description |
| Suite | A set of ready-made apps installed in one action; the platform switches on their links. `catalog_list` lists them; `suite_get` reads one, `suite_install` installs it |
| Template | A suite that also brings starter settings (forms, a pipeline, quick replies); the platform adds them itself once the apps are ready, and a part that waits for something first (such as a connected channel) later, also by itself |
| Gives / takes | What kinds of data an app hands out and accepts, as typed things such as `core.Person`, `content.Post`, `request.Request` |
| Link | Data flowing from one app to another, written `"<from>><to>"`, e.g. `"booking>crm"`. Connected links are in `list_apps` `links`, links that can be switched on in `proposed`. See the `beyonder-links` skill |
| Gap | Something an app wants that no app on the board gives (`wants`), or gives that no app takes (`unused`). A gap is not a link and cannot be connected; an app from the catalog that gives or takes that thing could fill it |
| Owner approval | After an install the company owner may have to approve the app on the board (`needs_owner` with a link to `/board/c/<cell>`). Approving is closed to agents |
| Pause | An app stops serving, its links wait, its data stays (`app_pause` / `app_resume`). A link can be paused on its own (`link_pause` / `link_resume`) |
| Archive | An app stops, its data is exported and kept 12 months (`app_archive`) |
| Remove | An app leaves the board; a ready-made app's project is archived and its data kept; its links leave the board (`app_remove`). Permanent deletion is not offered |
| App tools | The app's own MCP tools, called as the person (`apps_tools_list`, `app_read`, `app_write`). See the `beyonder-apps` skill |
| Journal | What happened to the company (`events_list`): business events, oldest first, in pages of up to 50. While `hasMore`, read on with `after` = `lastSequence`. `raw: true` is the platform's technical log: never use it to explain a board to the person |

## Rights

- `whoami` gives each company's `role` (`owner`, `admin`, `editor`, `viewer`, ...) and `mayEditBoard`; `list_apps`
  gives the board's `rights` (`role`, `mayCompose`, `viaAgency`). For a read-only role, say "you can look at this
  board but not change it", not the role id. When writes are refused, `writeRefusal` / `writeRefusalCode` say why.
- Who may pause, resume and archive is in the agent file (AGENT.md); others get `forbidden`.
- Some steps are only for a person, whatever their role: approving an app as owner, signing a bridge, choosing a plan
  or buying an app, a tool an app keeps for people. The answer carries a `link` to the screen where they do it.
- Inside an app the person's role in that app applies (`role_forbidden`, `no_place`: see `beyonder-errors`).
