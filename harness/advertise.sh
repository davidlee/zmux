# shellcheck shell=sh
# Sourced by each harness's hook.

# Advertises state $1, and prints the title to match. Fails when there is nothing to
# show.
advertise() {
  # A background subagent's tools can outlast the turn, and must not undo blocked.
  if [ "$1" = working ]; then
    case $(cat) in
      *'"agent_id"'*) return 1 ;;
    esac
  fi

  # Host or jail, the session is zmx-state's to find. Nothing printed, nothing written.
  labels=$(zmx-state "$1" 2>/dev/null)
  [ -n "$labels" ] || return 1

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

  # A jail has no ZMX_SESSION, so no name to fall back on.
  name=${project:+$project.$id}
  name=${name:-${ZMX_SESSION:-}}
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
  printf '%s' "${name:+$name | }${role:+$role | }$dir | $icon" | tr -d '\000-\037\177'
}
