#!/bin/sh
# Advertises an interactive Codex on the zmx session around it, writing the state
# hooks.json passes: blocked once a turn ends, working once one starts (DEC-009). It
# also sets the terminal's title, as Claude's does. Always exits 0, so a hook can't
# fail Codex.

[ -n "${ZMX_SESSION:-}" ] || exit 0

# Delegates inherit ZMX_SESSION, and nothing in a hook's input tells them from a TUI,
# but a TUI's stdout is a terminal (EVD-015). hooks.json execs this, so that Codex is
# our parent rather than its login shell.
terminal=/proc/$PPID/fd/1
[ -t 3 ] 2>/dev/null 3<>"$terminal" || exit 0

# shellcheck disable=SC1091
. "$(dirname "$(readlink -f "$0")")/../advertise.sh"
title=$(advertise "$1") || exit 0

# Codex gives hooks no way to set a title, and they have no /dev/tty, but its stdout
# is ours to write.
printf '\033]0;%s\007' "$title" >"$terminal"
