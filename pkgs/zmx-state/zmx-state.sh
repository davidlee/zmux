#!/bin/sh
# Writes state $1 on the zmx session around it, and prints that session's labels: the
# one command a harness calls. Always exits 0, and prints nothing when nothing was
# written, so a harness needs no test of its own for a session. A jail has its own
# zmx-state, with this contract, which relays to the host (flakes:IMP-070).

[ -n "${ZMX_SESSION:-}" ] || exit 0

# `done` and `failed` are a dispatcher's (ADR-002).
case ${1:-} in
  working | blocked) ;;
  *) exit 0 ;;
esac

zmx set . "state=$1" </dev/null >/dev/null 2>&1 || exit 0

# The write stood, so a title still has something to show.
labels=$(zmx get . </dev/null 2>/dev/null) || :
printf '%s' "${labels:-state=$1}"
