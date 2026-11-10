#!/bin/sh
# SessionStart hook: print the Beyonder agent file (AGENT.md); Claude Code adds a hook's stdout (exit 0) to the session context.
set -eu
cat "$(dirname "$0")/../../AGENT.md"
