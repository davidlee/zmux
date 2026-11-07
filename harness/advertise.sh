# shellcheck shell=sh
# Sourced by each harness's hook.

# The one place that touches the session: writes state $1 and prints its labels.
# zmux:IMP-009's `zmx-state` replaces this body, and works from a jail too.
write_state() {
  zmx set . "state=$1" >/dev/null 2>&1 || return 1
  zmx get . 2>/dev/null || :
}

# Advertises state $1, and prints the title to match. Fails when there is nothing to
# show.
advertise() {
  # A background subagent's tools can outlast the turn, and must not undo blocked.
  if [ "$1" = working ]; then
    case $(cat) in
      *'"agent_id"'*) return 1 ;;
    esac
  fi

  labels=$(write_state "$1") || return 1

  project=''
  id=''
  role=''
  for pair in $labels; do
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
  # A title is terminal data: a control character in a path could end it early.
  printf '%s' "${name:-$ZMX_SESSION}${role:+ | $role} | $dir | $icon" | tr -d '\000-\037\177'
}
