#!/bin/sh
# Advertises an interactive Claude Code on the zmx session around it, writing the
# state settings.json passes: blocked once a turn ends, working once one starts
# (DEC-009). It also sets the terminal's title, since a session running Claude has
# no prompt for zsh's zmx-title (IMP-008). Always exits 0, so a hook can't fail
# Claude Code.

# Delegates inherit ZMX_SESSION, and only a terminal has a human behind it.
[ -n "${ZMX_SESSION:-}" ] && [ "${CLAUDE_CODE_ENTRYPOINT:-}" = cli ] || exit 0

# shellcheck disable=SC1091
. "$(dirname "$(readlink -f "$0")")/../advertise.sh"
title=$(advertise "$1") || exit 0

# Hooks have no terminal: Claude Code writes the sequence for them.
printf '{"terminalSequence":"\\u001b]0;%s\\u0007"}\n' \
  "$(printf '%s' "$title" | sed 's/[\\"]/\\&/g')"
