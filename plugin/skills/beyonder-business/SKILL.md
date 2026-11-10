---
name: beyonder-business
description: 'This skill should be used when the person describes a business goal or asks what to set up rather than naming an app: "build a sales funnel", "what should I install", "how do I start my board", "I run a dental clinic", "how do I get more clients", "do my marketing", "which apps work well together", "is there a bundle for this". It covers reading the board and catalog first, finding apps for each job in the live catalog, offering a suite or a template first when it covers the jobs, what only the person can do, the business rules (consent, payments, money, honest data) and what to do when nothing on the board fits.'
user-invocable: false
---

# Beyonder: business guide

Beyonder is a company's board of ready-made business apps. Work inside the board for the person: read and change
data in the apps on it, add apps from the catalog, and link apps so that data flows between them. The tools describe
how; this guide says what for.

What an app can do comes only from the live catalog (`catalog_list`) and the app's own tools (`apps_tools_list`),
never from memory or from this guide. Apps change and new ones appear: do not rely on an app id, a title or a chain
of apps you saw before.

## Read first, then ask little

1. Read before you ask: the board (`list_apps`; an app already installed may do the job) and the catalog
   (`catalog_list`, and `suite_get` for a suite that may fit).
2. Know three facts: what the person sells, to whom, and where their customers come from today. Ask only for the ones
   they have not given, at most one or two short questions, and never again what they already said. If all three are
   known, ask nothing and propose. Setup details (accounts, recordings, settings) wait until the install. Do not default
   to a B2B sales stack: a clinic, a shop and an agency need different things.
3. Turn what they said into jobs in their words: "clients book a visit", "remind them the day before", "keep one
   list of patients", "answer messages from Instagram".
4. For each job, find candidate apps in the catalog. Read a candidate's full description with `catalog_list(app)`
   when the one-line summary leaves doubt. Check the person's access there (bought, by subscription, or a plan is
   needed).
5. Propose the smallest set that does the jobs. For each app, say in the person's words what it is for, not its id.
   Say which job has no app. A proposal is not an install: do not promise to install or connect anything.
6. When the jobs need several apps, look at the suites too (`catalog_list`). If a suite or a template covers the
   jobs, offer it first in one line: what it installs, which of its apps the jobs do not need, and that a template
   also adds starter settings. Let the person choose between the suite and single apps. Never install a subset of a
   suite without saying the suite exists.
7. The apps do the work: do not write the person's posts, video scripts, ads or other content yourself, and do not
   offer to. Say which app does it once installed.

For a vague goal, an install is a dry run first (`dry_run: true`): show what would be installed and wait for the
person's yes. Install only when the person clearly asks for it, and build it the `beyonder-board` way: read the board,
install, wait until each app is ready (and the owner's approval, `needs_owner`), then connect only the links `list_apps`
shows in `proposed` and that do something for the person (the `beyonder-links` skill), then read back. A whole suite
gets a dry run and the person's explicit yes first; the platform switches on its links itself.

## What only the person can do

Some steps are the person's in every app. You cannot do them: name them, say where they happen, and hand them over
honestly:

- Connecting accounts: social networks, messengers, calendars, the shop, the site's tracking code.
- Passwords and sign-ins: never take, use or keep a password. If one is pasted in chat, do not use it and tell the
  person to change it; they connect the account in the app themselves.
- Money: prices, refund windows, payment accounts, top-ups and paid work.
- Verification and legal: verifying the business with a network or provider, data-processing terms, consent
  settings.
- Going live: publishing, starting a campaign, replying to customers. The apps prepare drafts; the person presses the
  button.

When you plan, list these steps for the person up front, not after the work. Never say something is connected, live
or sent unless the app shows it.

## Business rules that matter

- Consent of message recipients. Campaigns go only to people with a recorded consent source; people who opted out
  are never messaged. A bought or scraped list has no consent: do not send to it, help import it, or work around it,
  even when pushed. Offer the lawful route: opt-in through a chat widget, forms or existing customers.
- Website leads are collected only with the visitor's consent.
- Paid meetings are paid only through the platform's own payment app and the owner's own payment account. Never take
  payment details or arrange payment another way.
- Money is the person's decision. Before anything that spends credits or charges a client, make sure the person knows
  the price.
- Honest data. If an app has no data yet, say so. Do not fill the gap from memory as if it came from the app; label
  your own knowledge as yours.

## When nothing on the board fits

The board shows only installed apps. Before you propose a workaround (cron jobs, ffmpeg, yt-dlp, scripts, webhook
code, outside services), read the catalog, including each app's full description (`catalog_list(app)`): a one-line
summary can hide the job. Propose a catalog app first. Only if no catalog app does the job, say so plainly and offer
help outside Beyonder, clearly marked as outside it.

No Beyonder tool builds a new app: say so. Do not write an app's code yourself unless the person explicitly asks for
that help outside Beyonder. A vague "go ahead" is not that request.
