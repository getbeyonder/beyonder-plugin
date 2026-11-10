---
name: beyonder-errors
description: 'This skill should be used when a beyonder MCP tool answers with a refusal, needs_owner or an unexpected result, or the person asks "why did it fail", "what does this error mean", "why was it refused". It covers outcome_unknown, needs_owner, needs_human, payment_required, "nothing to do", forbidden, not_found, conflict, feature_off, rate_limited, unauthorized, platform_unavailable, server_unreachable, platform_error, bad_request and the app codes no_place, role_forbidden, module_disabled, app_unreachable, app_refused.'
user-invocable: false
---

# Answers and refusals

A refusal comes with `code`, `error` (the platform's own words when it gave them), and often `hint` (what to do
next), `params` (valid choices) and `link` (the Beyonder screen where the person does it). Read `hint` and `params`
first. Tell the person in plain words what happened and what they can do.

## Not a failure

| Answer | What to do |
|---|---|
| "... already ...; nothing to do" | Nothing was written and nothing needs repeating. Say it is already so |
| `needs_owner: true` with `link` (after `app_install`, `approval` `needs_owner`, `unavailable` or `started`) | The app is installed and waits for the company owner's approval on the board at `link` (`/board/c/<cell>`). An agent may not approve. Do not `connect` it until `list_apps` shows it ready |

## Hand over to the person

| Code | What to do |
|---|---|
| `needs_human` | Only a person can do this (a bridge on a link, a tool an app keeps for people, a step closed to agents). Tell them to do it at `link`, or in the app opened from there. Do not retry |
| `payment_required` | Only a person can pay: no plan, the app is not bought, or the plan's app limit. Send them to `link`. Do not retry until they say it is done |
| `forbidden` | The person's role does not allow it (who may do what: AGENT.md). Suggest asking an owner or administrator |

## The state is unclear

| Code | What to do |
|---|---|
| `outcome_unknown` (`do_not_repeat`) | The write may or may not have happened. Read the state (`list_apps`, `link_status`, `suite_get`; for an app one of its reading tools with `app_read`). Never repeat it blindly |
| `conflict` | The state moved, or `connect` would take another link off. Read again (a dry run) before trying again |

## Fix the call

| Code | What to do |
|---|---|
| `bad_request` | Fix the argument as `params` / `hint` say: several companies (name one with `company`), an archived app without `data` (see `beyonder-board`), args that do not fit an app tool's schema (`params.problems`), `app_read` on a writing tool or `app_write` on a reading one, an app installed twice (`app_ambiguous`, `params.installations`) |
| `not_found` | Check the id with `companies_list`, `list_apps`, `catalog_list` or `apps_tools_list`; `params` often lists the valid choices. It is not proof that the app, tool or record does not exist: say the call failed; an app installed a moment ago may not be ready yet (`list_apps`) |
| `platform_error` | Tell the person what the platform said; retrying unchanged rarely helps |

## Wait or stop

| Code | What to do |
|---|---|
| `feature_off` | Beyonder has switched this feature off for everyone (not per company). Tell the person; do not retry |
| `rate_limited` | Wait `retryAfterSec`, then try once more |
| `platform_unavailable` | Try again later. A read or a dry run that got no answer sent nothing to be applied. With `platformCode` it is the platform's own stated reason, not an outage: tell the person; retrying will not help until that changes |
| `server_unreachable` | The CLI could not reach the beyonder server: no network, a wrong `--url`, or the server is down. Check the address (`beyonder-cli`, section 2) and the network. When the server is down, the MCP tools fail too (their connection drops or they are missing): it is the same outage. Tell the person and try again later |

## Sign-in

| Code | What to do |
|---|---|
| `unauthorized`, or the MCP connection asks to sign in again (`invalid_token`) | The sign-in ended or was revoked. The person reconnects the beyonder MCP and signs in to Beyonder again (through the CLI: `beyonder login`, see `beyonder-cli`) |

## App tools (`app_read`, `app_write`)

| Code | What to do |
|---|---|
| `needs_human` | The app keeps this tool for a person (its summary starts with "Person only"). Tell them to do it in the app |
| `no_place` | The person has no place in that app yet. They open the app once from the Beyonder board (`link`) to sign in to it through Beyonder, or ask the app's owner or administrator for access; then try again |
| `role_forbidden` | Their role in the app does not allow it; an owner or administrator of the app can do it, or give them a role that may |
| `module_disabled` | That part of the app is switched off in this company; an administrator of the app turns it on. Do not retry until then |
| `app_unreachable` | The app has no address yet or did not answer. Try again later |
| `app_refused` | Tell the person what the app said (`error`; `params.theApplicationSaid` and the rest of the app's answer). It is the app's own answer, not an outage of Beyonder or the app: do not call it one or suggest just trying again. Not a hand-over to a person. After a refused dry run nothing was written: fix the arguments (`app_tool_describe`) and dry-run again. When the hint says the app does not accept the platform's token yet (`app_token_refused`) or refused without saying why (`app_forbidden`, 403): tell the person, do not retry |
