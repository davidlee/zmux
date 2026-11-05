#!/bin/sh
# zmx with opinions.
#
# Installed as `zmx` by the nix overlay, so every caller inherits the
# convention without knowing it: a `<project>.<id>` name becomes `project` and
# `id` labels on the one attach that creates the session, a session born here
# is born in its own transient scope, and a dispatch is bracketed with `state`.
# Every other verb is the real zmx, byte for byte. VOCABULARY.md is the
# contract this implements.
#
# The real binary is addressed by absolute path, substituted at build time, so
# this script can never re-enter itself. Its only external command is
# systemd-run: the user's PATH stays the user's.
set -u

REAL_ZMX='@zmx@'
SCOPE='systemd-run --user --scope --collect --quiet'

say() { printf 'zmx: %s\n' "$*" >&2; }

# Refused: the caller's input is at fault.
die() {
  say "$*"
  exit 2
}

# Failed: the input was fine and the environment was not.
fail() {
  say "$*"
  exit 1
}

# Every character outside [a-zA-Z0-9_-] becomes '-'. By the time this runs a dot
# is inside a part: the separator was consumed by the first-dot split.
sanitise() {
  out=
  rest=$1
  while [ -n "$rest" ]; do
    char=${rest%"${rest#?}"}
    rest=${rest#?}
    case $char in
      [a-zA-Z0-9_-]) out=$out$char ;;
      *) out=$out- ;;
    esac
  done
  printf '%s' "$out"
}

# project and id, both empty for an undotted name. A part that sanitises away is
# refused: `project=` would delete a label rather than write one, and naming a
# session is the caller's job, so a name this wrapper would have to rewrite is
# refused rather than retargeted.
derive() {
  subject=$1
  case $subject in
    *.*)
      project=$(sanitise "${subject%%.*}")
      id=$(sanitise "${subject#*.}")
      if [ -z "$project" ] || [ -z "$id" ]; then
        die "cannot derive project and id from '$1'; name it <project>.<id>"
      fi
      ;;
    *)
      project=
      id=
      ;;
  esac
}

# Labels are create-time only, and a repeated --labels is not additive, so the
# caller's labels and ours are one token. Ours come last and win: they are
# derived from the name the caller just gave.
attach_labels() {
  if [ -n "$1" ]; then
    printf '%s project=%s id=%s' "$1" "$project" "$id"
  else
    printf 'project=%s id=%s' "$project" "$id"
  fi
}

# Existence by listing rather than by a per-session request: a session busy in a
# long task still answers. Labels cannot be written later, so this is what keeps
# an existing session unrelabelled.
session_exists() {
  names=$("$REAL_ZMX" ls --short 2>/dev/null) || return 1
  case "
$names
" in
    *"
$1
"*) return 0 ;;
  esac
  return 1
}

# The binary can exist with no user manager behind it (root, cron, a container),
# so ask the launcher rather than the PATH. /bin/sh is this script's own
# interpreter, so the probe assumes nothing about the user's PATH.
# shellcheck disable=SC2086 # the prefix is argv in a variable; the split is the point
scope_is_usable() {
  command -v systemd-run >/dev/null 2>&1 &&
    $SCOPE /bin/sh -c : >/dev/null 2>&1
}

# The launcher is data: an argv prefix, word-split on purpose. A caller's
# ZMX_LAUNCHER is taken at its word and its failures are the caller's to see.
# The default is a transient user scope where one works, and nothing where it
# does not: failing to attach is worse than failing to be durable.
launcher() {
  if [ -n "${ZMX_LAUNCHER+set}" ]; then
    printf '%s' "$ZMX_LAUNCHER"
  elif scope_is_usable; then
    printf '%s' "$SCOPE"
  fi
}

#   launch exec CMD...  replace this process (the interactive verb)
#   launch wait CMD...  run it and return (a creation dispatch)
launch() {
  mode=$1
  shift
  prefix=$(launcher)
  # shellcheck disable=SC2086 # the prefix is argv in a variable; the split is the point
  set -- $prefix "$@"
  if [ "$mode" = exec ]; then
    exec "$@"
  fi
  "$@"
}

do_attach() {
  # attach [--labels KV] NAME [command...]
  # Without a name there is nothing to name: the refusal is zmx's to make.
  caller_labels=
  if [ "${1-}" = --labels ]; then
    [ $# -ge 3 ] || exec "$REAL_ZMX" attach "$@"
    caller_labels=$2
    shift 2
  fi
  [ $# -ge 1 ] || exec "$REAL_ZMX" attach
  name=$1
  shift
  derive "$name"
  if [ -n "$project" ] && ! session_exists "$name"; then
    launch exec "$REAL_ZMX" attach \
      --labels "$(attach_labels "$caller_labels")" "$name" "$@"
  elif [ -n "$caller_labels" ]; then
    launch exec "$REAL_ZMX" attach --labels "$caller_labels" "$name" "$@"
  else
    launch exec "$REAL_ZMX" attach "$name" "$@"
  fi
}

do_run() {
  # run NAME [command...], with -d anywhere after the name.
  [ -n "${1-}" ] || exec "$REAL_ZMX" run "$@"
  name=$1
  shift
  if [ "$name" = . ]; then
    [ -n "${ZMX_SESSION:-}" ] ||
      die "'.' means the current session, and ZMX_SESSION is not set"
    name=$ZMX_SESSION
  fi
  derive "$name"

  # zmx takes -d wherever it appears, so it is never part of the command.
  detached=
  has_command=
  for arg; do
    if [ "$arg" = -d ]; then detached=1; else has_command=1; fi
  done

  if ! session_exists "$name"; then
    # `zmx run` creates the session when it is absent, and takes no labels, so
    # creation is a dispatch of its own. Its chatter is not the caller's output.
    # Anything short of a labelled session stops here: the plain `zmx run` below
    # would otherwise create one of its own, unlabelled and outside any scope.
    err=$(launch wait "$REAL_ZMX" run "$name" true 2>&1 >/dev/null) ||
      fail "cannot create session '$name': $err"
    if [ -n "$project" ]; then
      "$REAL_ZMX" set "$name" "project=$project id=$id" >/dev/null 2>&1 ||
        fail "cannot label session '$name'"
    fi
  fi

  # No command and nothing on stdin is a usage error, not a task to bracket.
  if [ -z "$has_command" ] && [ ! -p /dev/stdin ] && [ ! -f /dev/stdin ]; then
    exec "$REAL_ZMX" run "$name" "$@"
  fi

  "$REAL_ZMX" set "$name" state=working >/dev/null 2>&1
  "$REAL_ZMX" run "$name" "$@"
  status=$?

  # A detached dispatch has not returned, so working is still the truth.
  if [ -z "$detached" ]; then
    if [ "$status" -eq 0 ]; then
      "$REAL_ZMX" set "$name" state=done >/dev/null 2>&1
    else
      "$REAL_ZMX" set "$name" state=failed >/dev/null 2>&1
    fi
  fi
  exit "$status"
}

# ZMX_RAW=1: one invocation exactly as zmx shipped it, rewrites and all off.
if [ "${ZMX_RAW:-}" = 1 ]; then
  exec "$REAL_ZMX" "$@"
fi

case ${1-} in
  '') exec "$REAL_ZMX" ;;
  attach | a)
    shift
    do_attach "$@"
    ;;
  run | r)
    shift
    do_run "$@"
    ;;
  *) exec "$REAL_ZMX" "$@" ;;
esac
