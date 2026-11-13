#!/bin/sh
# PreToolUse hook for the beyonder writes that take something away: app_remove and app_archive.
#
# MCP (hooks.json matcher: app_remove, app_archive, app_write, app_restore under any server name holding "beyonder"): a
# dry run passes ("allow"). A real app_remove or app_archive asks the person ("ask"): "ask" makes Claude Code show its
# approval prompt even when the person once chose "always allow" for the tool. A real app_write or app_restore prints
# nothing, so Claude Code's normal permissions decide and "always allow" works; they are matched only so that their dry
# run needs no prompt (both are destructiveHint on the server; the plugin asks only on remove/archive). Any other
# matched tool asks (fail-safe). A dry run is `dry_run: true` as a key of tool_input itself, never one nested deeper:
# app_write's `args` are the app tool's own arguments, and an `args: {"dry_run": true}` there is not the server's dry
# run.
#
# Bash and PowerShell (hooks.json: matcher Bash|PowerShell, `if` *beyonder*, so a path or sh -c is seen too): the
# beyonder CLI does the same writes. A command that runs `beyonder app_remove|app_archive ...` without --dry-run /
# --help / --schema asks. Every other beyonder command (app_write, an app tool `beyonder <app> <tool>`, app_restore,
# upload, reads, the CLI installer) prints nothing, so Claude Code's own permissions decide. A CLI dry run is never
# "allow": that would approve the whole shell command, whatever else it runs.
# `beyonder`, `beyonder.exe`, `beyonder.cmd` and any path to them (Windows `\` read as `/`) start a CLI command only in
# command position: the first word of a segment (the start, or after `;` `&` `|` `(` `{` a backtick or a new line),
# after `VAR=value`, after a prefix word (env exec command sudo nohup time nice xargs, or if then else elif do while
# until !; flags right after one, like `-c`, are skipped), or the first word inside `sh|bash|zsh -c '...'`. So
# `git -C ~/src/beyonder diff`, `grep -rn beyonder src` and `echo beyonder crm deal` are not the CLI.
# A `#` at the start of an unquoted word is a comment: it ends the beyonder command, so `app_remove crm # --dry-run`
# asks.
# Words are split with quote state (outside quotes, inside '...', inside "..."): a blank or one of ; & | ( ) ` < > { }
# inside quotes is part of the word, so `--company "Acme Inc"`, `--company='Acme Inc'` and `-d '{"app":"crm"}'` do not
# hide the command; `{` and `}` split only as a word of their own (a brace group), so `-d {}` is a flag value. The quotes
# are removed from the word. A quoted word after sh -c (env, sudo ...) and the body of a $(...) or backtick substitution
# inside double quotes are scanned again as command lines.
# Known limit: this is a tokenizer, not a full sh parser: a command hidden in a variable or eval, in a shell escape
# (`\"`, `\'`), in a file the shell runs, or after a prefix word's value (`sudo -u bob beyonder ...`,
# `nice -n 5 beyonder ...`) is not seen (Claude Code's own Bash permission prompt still applies).
#
# awk walks the JSON once (strings and escapes skipped, linear on large inputs) and looks only at keys of the object
# under the event's "tool_input".
#
# --as codex (codex/hooks.json, Codex only; README "Codex"): Codex does not support "ask" (it marks the hook failed and
# lets the call through), and it asks the person by itself before every destructiveHint MCP tool (app_remove,
# app_archive, app_restore, app_write), dry runs too. So in this mode an MCP tool prints nothing, and a shell command
# that runs `beyonder app_remove|app_archive` without --dry-run / --help / --schema is denied, with a reason that sends
# the model to the MCP tool (which Codex asks about): the same commands Claude Code's hook asks about (owner 10.11).
# Everything else prints nothing, `beyonder app_restore` and `beyonder app_write` too (Codex's own sandbox and approval
# policy decide). `beyonder <app> <tool>` (an app tool, read or write) is not told apart: not denied.
# POSIX sh and POSIX awk only (BSD awk on macOS, gawk / mawk / busybox awk on Linux).
set -eu
as=claude
case "${1:-}:${2:-}" in
  :) ;;
  --as:claude|--as:codex) as=$2 ;;
  *) echo "approve-write.sh: usage: approve-write.sh [--as claude|codex] < event.json" >&2; exit 2 ;;
esac
asked='^(app_remove|app_archive)$' # the same in both modes
event=$(cat)
# The first "tool_name" is the event's own: one inside tool_input would be escaped (\") or come later.
tool=$(printf '%s' "$event" | grep -o '"tool_name" *: *"[A-Za-z0-9_-]*"' | head -n 1 | sed 's/.*"\([A-Za-z0-9_-]*\)"$/\1/')
tool=${tool##*__}
mode=mcp
case "$tool" in Bash|PowerShell) mode=bash ;; esac

verdict=$(printf '%s' "$event" | awk -v mode="$mode" -v tool="$tool" -v asked="$asked" -v q="'" '
function unescape(v) {
  gsub(/\\\\/, SUBSEP, v); gsub(/\\"/, "\"", v); gsub(/\\n/, NL, v); gsub(/\\[rt]/, " ", v); gsub(/\\\//, "/", v); gsub(SUBSEP, "/", v)
  return v
}
function judge(inb, dry, help, cmd) { # one shell segment of beyonder words seen: cmd, dry, help
  if (!inb || dry || help || reason != "") return
  if (cmd ~ asked) reason = "beyonder " cmd " will change the board"
}
function push(tok, tq, tsep, n, text, quoted, sep) { n++; tok[n] = text; tq[n] = quoted; tsep[n] = sep; return n }
function sub_add(subs, text) { subs[0]++; subs[subs[0]] = text }
function substs(subs, seg,   t, a, k) { # the command substitutions $(...) and `...` inside one double-quoted string
  t = seg
  while ((a = index(t, "$(")) > 0) { t = substr(t, a + 2); k = index(t, ")"); if (!k) { sub_add(subs, t); break } sub_add(subs, substr(t, 1, k - 1)); t = substr(t, k + 1) }
  t = seg
  while ((a = index(t, "`")) > 0) { t = substr(t, a + 1); k = index(t, "`"); if (!k) { sub_add(subs, t); break } sub_add(subs, substr(t, 1, k - 1)); t = substr(t, k + 1) }
}
# Words with quote state: outside quotes, inside '"'"'...'"'"', inside "...". A blank or one of ; & | ( ) ` < > { } inside quotes is part of
# the word; outside quotes it ends the word, and ; & | ( ) ` < > and a new line also end the segment (tsep). { and } do
# that only as a word of their own (a brace group), so `{}` and `{"a":1}` are words. The quotes are removed from the word
# (tq says it had some). A # at the start of an unquoted word is a comment up to the next new line. A quote that is
# never closed is an ordinary character. Returns the number of tokens; subs holds the $(...) and `...` bodies seen
# inside double quotes (they run, even there).
function tokenize(s, tok, tq, tsep, subs,   n, cur, has, qd, r, i, c, j, nx, flush, sep, lit, seg) {
  n = 0; cur = ""; has = 0; qd = 0; subs[0] = 0; r = s
  while (r != "") {
    if (!match(r, special)) { cur = cur r; has = 1; break }
    i = RSTART
    if (i > 1) { cur = cur substr(r, 1, i - 1); has = 1 }
    c = substr(r, i, 1); r = substr(r, i + 1)
    flush = 0; sep = 0; lit = ""
    if (c == " " || c == "\t" || c == "\r" || c == "\n") flush = 1
    else if (c == "{" || c == "}") {
      nx = substr(r, 1, 1)
      if (!has && (nx == "" || nx ~ bnd)) { flush = 1; sep = 1 } else lit = c
    }
    else if (c == "#") {
      if (!has) { sep = 1; j = index(r, NL); r = j ? substr(r, j) : "" } else lit = c
    }
    else if (c == q || c == "\"") {
      j = index(r, c)
      if (j) {
        seg = substr(r, 1, j - 1); r = substr(r, j + 1); lit = seg; has = 1; qd = 1
        if (c == "\"") substs(subs, seg)
      }
    }
    else { flush = 1; sep = 1 } # NL ; & | ( ) ` < >
    if (flush && has) { n = push(tok, tq, tsep, n, cur, qd, 0); cur = ""; has = 0; qd = 0 }
    if (sep) n = push(tok, tq, tsep, n, "", 0, 1)
    if (lit != "") { cur = cur lit; has = 1 }
  }
  if (has) n = push(tok, tq, tsep, n, cur, qd, 0)
  return n
}
function scan(str, depth,   tok, tq, tsep, subs, n, j, k, x, lx, inb, pos, pre, cmd, dry, help, skip) {
  n = tokenize(str, tok, tq, tsep, subs)
  inb = 0; pos = 1; pre = 0
  for (j = 1; j <= n + 1; j++) {
    if (j > n || tsep[j]) { judge(inb, dry, help, cmd); inb = 0; pos = 1; pre = 0; continue }
    x = tok[j]
    if (inb && skip) { skip = 0; continue }
    if (x == "") continue
    lx = tolower(x)
    if (!inb) { # command position: pos (still at the start of the segment), pre (after a prefix word or sh -c)
      if (!pos) continue
      # a quoted word after sh -c / env / sudo ... is a command line of its own (sh -c '"'"'beyonder app_remove crm'"'"')
      if (pre && tq[j] && depth < 6) scan(x, depth + 1)
      if (lx ~ /(^|\/)beyonder(\.exe|\.cmd)?$/) { inb = 1; cmd = ""; dry = 0; help = 0; skip = 0 }
      else if (lx in prefix || lx ~ /(^|\/)(sh|bash|zsh)$/) pre = 1
      else if (!(x ~ /^[A-Za-z_][A-Za-z0-9_]*=/ || (pre && x ~ /^-/))) pos = 0
      continue
    }
    if (x == "--url" || x == "--company" || x == "-d" || x == "--app") skip = 1
    else if (x == "--dry-run") dry = 1
    else if (x == "--help" || x == "-h" || x == "--schema" || x == "--version") help = 1
    else if (x ~ /^-/) continue
    else if (cmd == "") cmd = x
  }
  if (depth < 6) for (k = 1; k <= subs[0]; k++) scan(subs[k], depth + 1)
}
{ s = s $0 "\n" } END {
  # Split on quotes: odd parts are outside strings, even parts inside (a part ending in an odd run of backslashes ends
  # at an escaped quote, so the string goes on). split, gsub and match are linear; substr walks only short pieces,
  # since BSD awk counts characters from the start on every substr.
  np = split(s, p, "\""); d = 0; ins = 0; str = ""; last = ""; pending = ""; found = 0; command = ""
  for (i = 1; i <= np; i++) {
    if (ins) {
      # Only the Bash command is kept whole; other strings are only compared with short keys, so 32 chars do.
      # Known limit: a command with very many escaped quotes is joined piece by piece (quadratic); past the 10 s
      # timeout it is blocked (onFailure), never let through.
      if (i < np && match(p[i], /\\+$/) && RLENGTH % 2 == 1) {
        if (whole || length(str) < 32) str = str p[i] "\""
        continue
      }
      last = str p[i]; str = ""; ins = 0
      if (d == 2 && obj[2] == "tool_input" && pending == "command") command = last
      continue
    }
    part = p[i]; gsub(/[ \t\r\n]+/, "", part)
    ns = split(part, seg, ",")
    for (k = 1; k <= ns; k++) {
      if (k > 1) pending = ""
      x = seg[k]; L = length(x)
      for (j = 1; j <= L; j++) {
        c = substr(x, j, 1)
        if (c == "{") { d++; obj[d] = pending; pending = "" }
        else if (c == "}") { d--; pending = "" }
        else if (c == "[") pending = ""
        else if (c == ":") {
          pending = last
          if (d == 2 && obj[2] == "tool_input" && last == "dry_run" && substr(x, j + 1, 4) == "true") found = 1
        }
      }
    }
    if (i < np) { ins = 1; whole = (d == 2 && obj[2] == "tool_input" && pending == "command") }
  }
  if (mode == "mcp") { print (found ? "allow" : tool ~ /^(app_write|app_restore)$/ ? "pass" : "ask"); exit }
  split("env exec command sudo nohup time nice xargs if then else elif do while until !", kw, " ")
  for (j in kw) prefix[kw[j]] = 1
  NL = "\001"; special = "[ \t\r\n\001;&|()`<>{}" q "\"#]"; bnd = "[ \t\r\n\001;&|()`<>]"
  # A ${...} expansion (inner first, so ${a:-${b}} too) is one word, not a brace group: its braces must not split.
  v = unescape(command); while (gsub(/\$\{[^{}]*\}/, "$VAR", v)) ; reason = ""
  scan(v, 0)
  print (reason == "" ? "pass" : "ask " reason)
}')

if [ "$as" = codex ]; then
  case "$mode:$verdict" in
    "bash:ask "*)
      reason="Beyonder: ${verdict#ask } and this plugin does not run it through the shell in Codex. Call the beyonder MCP tool ${verdict#ask beyonder }"
      reason=${reason% will change the board}
      reason="$reason instead (Codex asks the person before it; do its dry run first), or ask the person to run the command in their own terminal."
      printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason" ;;
  esac
  exit 0
fi
case "$verdict" in
  allow) decision=allow reason="Beyonder: ${tool:-write} dry run, nothing changes" ;;
  pass) exit 0 ;;
  "ask "*) decision=ask reason="Beyonder: ${verdict#ask }" ;;
  *) decision=ask reason="Beyonder: ${tool:-this tool} will change the board" ;;
esac
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$decision" "$reason"
