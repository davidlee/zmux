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
# this script can never re-enter itself. It uses no external command but
# `command -v systemd-run`: the user's PATH stays the user's.
set -u

REAL_ZMX='@zmx@'

die() {
  printf 'zmx: %s\n' "$*" >&2
  exit 2
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

# The launcher is data: an argv prefix, word-split on purpose, defaulting to a
# transient user scope where systemd-run exists and to nothing where it does
# not. Failing to attach is worse than failing to be durable.
#
#   launch exec CMD...  replace this process (the interactive verb)
#   launch wait CMD...  run it and return (a creation dispatch)
launch() {
  mode=$1
  shift
  if [ -n "${ZMX_LAUNCHER+set}" ]; then
    prefix=$ZMX_LAUNCHER
  elif command -v systemd-run >/dev/null 2>&1; then
    prefix='systemd-run --user --scope --collect --quiet'
  else
    prefix=
  fi
  # shellcheck disable=SC2086 # the prefix is argv in a variable; the split is the point
  set -- ${prefix:-} "$@"
  if [ "$mode" = exec ]; then
    exec "$@"
  fi
  "$@"
}

do_attach() {
  # attach [--labels KV] NAME [command...]
  if [ "${1-}" = --labels ]; then
    caller_labels=$2
    shift 2
    name=${1-}
    shift
  else
    caller_labels=
    name=${1-}
    shift
  fi
  [ -n "$name" ] || launch exec "$REAL_ZMX" attach
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
  # run NAME [-d] [command...]
  name=${1-}
  [ -n "$name" ] || launch exec "$REAL_ZMX" run
  shift
  if [ "$name" = . ]; then
    [ -n "${ZMX_SESSION:-}" ] ||
      die "'.' means the current session, and ZMX_SESSION is not set"
    name=$ZMX_SESSION
  fi
  derive "$name"

  detached=
  if [ "${1-}" = -d ]; then detached=1; fi

  if ! session_exists "$name"; then
    # `zmx run` creates the session when it is absent, and takes no labels, so
    # creation is a dispatch of its own. Its chatter is not the caller's output.
    launch wait "$REAL_ZMX" run "$name" true >/dev/null 2>&1
    if [ -n "$project" ]; then
      "$REAL_ZMX" set "$name" "project=$project id=$id" >/dev/null 2>&1
    fi
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
