#!/bin/sh
# Run a command in a new `<project>.<n>` session, or a shell with no command.
#
# A caller of the wrapper, not part of it (ADR-003): it composes the name and
# leaves labels and the scope to `zmx attach`. A command that a session would
# harm runs directly. A session swallows the command's exit status, and loses
# the output of one that exits at once, so a wrong guess errs towards running
# directly, which is what the caller would have got without this script.
#
# The wrapper is addressed by absolute path, substituted at build time. Everything
# else is shell builtins: the user's PATH stays the user's.
set -u

ZMX='@zmx@'

# Reads the harness's argv, not its name: a subcommand, a prompt or a one-shot
# flag means nobody is staying to talk to it.
is_one_shot() {
  case ${1-} in
    '' | -*) ;;
    *) return 0 ;;
  esac
  for arg; do
    case $arg in
      -p | --print | -v | --version | -h | --help) return 0 ;;
    esac
  done
  return 1
}

# Already in a session, nested attach does nothing, and silently. Without a
# terminal there is nobody to attach.
runs_directly() {
  [ -n "${ZMX_SESSION:-}" ] || [ ! -t 0 ] || [ ! -t 1 ] && return 0
  shift
  is_one_shot "$@"
}

# The nearest directory that is a project, by active-projects' markers, or the
# working directory. $HOME is never one, even when it is a repository.
project_dir() {
  dir=$PWD
  while [ -n "$dir" ] && [ "$dir" != "${HOME:-}" ]; do
    if [ -e "$dir/.git" ] || [ -e "$dir/.jj" ] || [ -e "$dir/.project" ]; then
      printf '%s' "$dir"
      return
    fi
    dir=${dir%/*}
  done
  printf '%s' "$PWD"
}

# A name holds one dot, so the project can't hold any.
fold_dots() {
  rest=$1
  while [ "${rest#*.}" != "$rest" ]; do
    rest=${rest%%.*}_${rest#*.}
  done
  printf '%s' "$rest"
}

# One above the highest number in use. A name is never reused: attaching to a
# live session joins it, and the command is dropped without a word.
next_number() {
  "$ZMX" ls --short 2>/dev/null | {
    highest=0
    while IFS= read -r name; do
      number=${name#"$1".}
      case $number in
        "$name" | '' | 0* | *[!0-9]*) continue ;;
      esac
      [ "$number" -le "$highest" ] || highest=$number
    done
    printf '%s' $((highest + 1))
  }
}

if [ $# -gt 0 ] && runs_directly "$@"; then
  exec "$@"
fi

dir=$(project_dir)
project=$(fold_dots "${dir##*/}")
exec "$ZMX" attach "$project.$(next_number "$project")" "$@"
