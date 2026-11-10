---
name: beyonder-links
description: 'This skill should be used when the person wants two Beyonder apps to share data or asks about a link: "connect Booking to AI CRM", "why is data not passing", "why does the link not work", "pause the link", "resume the link", "turn the link back on". It covers connect, link_pause, link_resume and link_status, proposed links, gaps and bridges.'
user-invocable: false
---

# Links between apps

A link carries data from one app to another. Each app says what it **gives** and what it **takes** as typed things
(`core.Person`, `content.Post`, `request.Request`, ...); where one app gives what another takes, the board offers a
link. A link is written `"<from app id>><to app id>"` with the ids `list_apps` shows, e.g. `"booking>crm"`.

## Where to see them

`list_apps(company)`:

- `links`: connected links `{link, thing, acceptance}`;
- `proposed`: links that can be switched on `{link, thing}`. Only these can be connected;
- `gaps`: what an app wants that no app on the board gives (`wants`), or gives that no app takes (`unused`). A gap is
  not a link: an app from `catalog_list` that gives or takes that thing could fill it;
- `sync.failing`: data pairs with their last error.

The `app_install` dry run lists `proposedLinks`: the links the new app would be offered.

`link_status(link)` shows one link: its data pairs (`source -> target`, last success, staleness, last error), its
holds (pauses), its state and its journal. A proposed link has no state yet.

## Switching a link on: proposed -> connect

1. Both apps must be on the board, and the new one ready (`list_apps`), see `beyonder-board`.
2. `connect(link)` switches on the proposed link: all its proposed things, or only the named `things`. It is a
   creating change: the person's clear request is the yes. Its dry run (`dry_run: true`) is the platform's own:
   `verdict`, `lines`, `reactionsTurnedOn`. Use it when the request is vague.
3. Already connected: "nothing to do". No proposed line between the two: `not_found` with `params.proposed`.
4. `connect` never takes another link off: if switching this one on would, it answers `conflict` and nothing changes.
5. A line that needs a **bridge** (a sensitive or mismatched field) answers `needs_human`: only a person signs a
   bridge, on the company's board (the `link`). Tell them; do not retry.
6. Read back with `list_apps` (the link is in `links`) or `link_status`.

## Holding a link: link_pause, link_resume

- `link_pause` holds the data of one connected link: nothing passes, nothing is deleted, and what the source gathers
  while paused passes on resume. `link_resume` releases it. Both are reversible changes.
- A link with no data pair yet cannot be paused (`not_found`). Beyonder can switch links off for everyone (not per
  company): then both answer `feature_off`. Tell the person; nothing can be paused or resumed then.
- A hold shows in `link_status` `holds`.

Removing a link, field mapping and reactions are not tools yet: the person does them on the board.
