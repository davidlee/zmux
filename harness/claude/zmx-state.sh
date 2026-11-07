#!/bin/sh
# Advertises an interactive Claude Code on the zmx session around it, writing the
# state settings.json passes: blocked once a turn ends, working once one starts
# (DEC-009). It also sets the terminal's title, since a session running Claude has
# no prompt for zsh's zmx-title (IMP-008). Always exits 0, so a hook can't fail
# Claude Code.

# Delegates inherit ZMX_SESSION, and only a terminal has a human behind it.
[ -n "${ZMX_SESSION:-}" ] && [ "${CLAUDE_CODE_ENTRYPOINT:-}" = cli ] || exit 0

# A background subagent's tools can outlast the turn, and must not undo blocked.
if [ "$1" = working ]; then
  case $(cat) in
    *'"agent_id"'*) exit 0 ;;
  esac
fi

zmx set . "state=$1" >/dev/null 2>&1 || exit 0

project=''
id=''
role=''
for pair in $(zmx get . 2>/dev/null); do
  case $pair in
    project=*) project=${pair#*=} ;;
    id=*) id=${pair#*=} ;;
    role=*) role=${pair#*=} ;;
  esac
done

name=${project:+$project.$id}
dir=$PWD
case $dir in
  "$HOME" | "$HOME"/*) dir="~${dir#"$HOME"}" ;;
esac
# The same fields and icons as zmx-title in zsh, and dl-zmx--state-icons in Emacs.
case $1 in
  working) icon=◐ ;;
  blocked) icon=🔔 ;;
esac
title="${name:-$ZMX_SESSION}${role:+ | $role} | $dir | $icon"

# Hooks have no terminal: Claude Code writes the sequence for them.
printf '{"terminalSequence":"\\u001b]0;%s\\u0007"}\n' \
  "$(printf '%s' "$title" | sed 's/[\\"]/\\&/g')"
