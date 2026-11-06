#!/usr/bin/env bash
# argv assertions for the zmx wrapper.
#
# A stub `zmx` and a stub `systemd-run` record their argv, and the wrapper is
# built with the stub's path substituted for the real binary, exactly as the
# derivation does. Nothing here runs a real zmx or a real systemd, and nothing
# outlives a case (CON-004): what is asserted is the argv a caller builds.
set -uo pipefail

here=$(cd -- "$(dirname -- "$0")" && pwd)
root=$(cd -- "$here/.." && pwd)
wrapper_src=$root/pkgs/zmx/wrapper.sh
launcher_src=$root/pkgs/zmx-new/zmx-new.sh

if [ ! -f "$wrapper_src" ]; then
  printf 'FAIL no wrapper to test: %s\n' "$wrapper_src" >&2
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
work=$tmp/work

# --- fixture ---------------------------------------------------------------

# One directory per concern, reset before every case. `bin` holds the built
# wrapper, the zmx stub and the systemd-run stub; `bare` is an empty PATH, for
# the machine with no usable user systemd. The stubs are pure shell, so an
# empty PATH is enough to run them.
setup() {
  rm -rf -- "$work"
  mkdir -p "$work/bin" "$work/bare" "$work/zmx-argv" "$work/sd-argv" "$work/harness-argv"
  : > "$work/sessions"
  printf '0\n' > "$work/zmx-seq"
  printf '0\n' > "$work/sd-seq"
  export ZMX_STUB_SESSIONS=$work/sessions \
    ZMX_STUB_SEQ=$work/zmx-seq \
    ZMX_STUB_LOG=$work/zmx-argv \
    SD_STUB_SEQ=$work/sd-seq \
    SD_STUB_LOG=$work/sd-argv \
    HARNESS_STUB_LOG=$work/harness-argv
  unset ZMX_RAW ZMX_LAUNCHER ZMX_SESSION ZMX_STUB_RUN_EXIT ZMX_STUB_RUN_HOLD ZMX_STUB_WAIT_EXIT ZMX_STUB_SET_FAIL SD_STUB_FAIL HARNESS_STUB_EXIT
  install -m 0755 "$here/stubs/zmx" "$work/bin/zmx-stub" || return 1
  install -m 0755 "$here/stubs/systemd-run" "$work/bin/systemd-run" || return 1
  sed "s|@zmx@|$work/bin/zmx-stub|" "$wrapper_src" > "$work/bin/zmx" || return 1
  chmod 0755 "$work/bin/zmx"
  install -m 0755 "$here/stubs/harness" "$work/bin/harness" || return 1
  sed "s|@zmx@|$work/bin/zmx|" "$launcher_src" > "$work/bin/zmx-new" || return 1
  chmod 0755 "$work/bin/zmx-new"
}

# The wrapper, with the systemd-run stub on PATH and without it.
zmx_on_path() { PATH=$work/bin "$work/bin/zmx" "$@"; }
zmx_bare() { PATH=$work/bare "$work/bin/zmx" "$@"; }

# The launcher, from a directory, with and without a terminal. `script` gives it a
# pty and is resolved before PATH narrows; -e carries the launcher's status out.
launcher_argv() {
  printf 'cd %q && PATH=%q HOME=%q' "$1" "$work/bare" "$work/home"
  shift
  printf ' %q' "$work/bin/zmx-new" "$@"
}
new_on_a_tty() { script -qefc "$(launcher_argv "$@")" /dev/null > /dev/null; }
new_off_a_tty() { (cd "$1" && shift && PATH=$work/bare HOME=$work/home "$work/bin/zmx-new" "$@"); }

# A directory under the fixture's $HOME, holding the given project markers.
project_dir() {
  local dir=$work/home/$1 marker
  shift
  mkdir -p "$dir"
  for marker; do mkdir -p "$dir/$marker"; done
  printf '%s' "$dir"
}

# Seed an existing session, as another zmx already created it.
have_session() { printf '%s\n' "$1" >> "$work/sessions"; }

# --- assertions ------------------------------------------------------------

dump() {
  local f
  for f in "$1"/*; do
    [ -e "$f" ] && printf '    %s: %s\n' "${f##*/}" "$(tr '\0' '|' < "$f")"
  done
  return 0
}

assert_calls() {
  local got
  got=$(find "$1" -type f | wc -l)
  if [ "$got" -ne "$2" ]; then
    printf '  %s: expected %s calls, got %s\n' "${1##*/}" "$2" "$got"
    dump "$1"
    return 1
  fi
}

# assert_argv LOGDIR INDEX ARG... — one recorded call, arg for arg.
assert_argv() {
  local dir=$1 idx=$2 arg
  shift 2
  if [ ! -f "$(printf '%s/%03d' "$dir" "$idx")" ]; then
    printf '  no call %s in %s\n' "$idx" "${dir##*/}"
    dump "$dir"
    return 1
  fi
  : > "$tmp/want"
  for arg in "$@"; do printf '%s\0' "$arg" >> "$tmp/want"; done
  if ! cmp -s "$(printf '%s/%03d' "$dir" "$idx")" "$tmp/want"; then
    printf '  argv[%s] got:  %s\n' "$idx" "$(tr '\0' '|' < "$(printf '%s/%03d' "$dir" "$idx")")"
    printf '  argv[%s] want: %s\n' "$idx" "$(tr '\0' '|' < "$tmp/want")"
    return 1
  fi
}

# await_call LOGDIR INDEX — a call made by a process the case does not wait on.
await_call() {
  local tries=100
  while [ ! -f "$(printf '%s/%03d' "$1" "$2")" ]; do
    tries=$((tries - 1))
    if [ "$tries" -eq 0 ]; then
      printf '  no call %s in %s after 5s\n' "$2" "${1##*/}"
      dump "$1"
      return 1
    fi
    sleep 0.05
  done
}

assert_status() {
  if [ "$1" -ne "$2" ]; then
    printf '  exit status: expected %s, got %s\n' "$2" "$1"
    return 1
  fi
}

assert_stderr() {
  if ! grep -q -- "$1" "$tmp/err"; then
    printf '  stderr: wanted "%s", got "%s"\n' "$1" "$(cat "$tmp/err")"
    return 1
  fi
}

assert_no_session() {
  if grep -qx -- "$1" "$work/sessions"; then
    printf '  session "%s" exists\n' "$1"
    return 1
  fi
}

# assert_no_dispatch NAME COMMAND — `run NAME COMMAND` was never called.
assert_no_dispatch() {
  local want calls
  want=$(printf 'run|%s|%s|' "$1" "$2")
  calls=$(dump "$ZMX_STUB_LOG")
  case $calls in
    *"$want"*)
      printf '  dispatched: %s\n' "$want"
      return 1
      ;;
  esac
}

# --- attach ----------------------------------------------------------------

attach_names_and_labels_at_creation() {
  zmx_bare attach p.i nu
  assert_calls "$ZMX_STUB_LOG" 2
  assert_argv "$ZMX_STUB_LOG" 1 ls --short
  assert_argv "$ZMX_STUB_LOG" 2 attach --labels 'project=p id=i' p.i nu
}

attach_leaves_an_undotted_name_alone() {
  zmx_bare attach dev nu
  assert_calls "$ZMX_STUB_LOG" 1
  assert_argv "$ZMX_STUB_LOG" 1 attach dev nu
}

attach_never_relabels_an_existing_session() {
  have_session p.i
  zmx_bare attach p.i nu
  assert_calls "$ZMX_STUB_LOG" 2
  assert_argv "$ZMX_STUB_LOG" 1 ls --short
  assert_argv "$ZMX_STUB_LOG" 2 attach p.i nu
}

attach_keeps_a_callers_labels_and_adds_its_own() {
  zmx_bare attach --labels role=worker p.i
  assert_calls "$ZMX_STUB_LOG" 2
  assert_argv "$ZMX_STUB_LOG" 2 attach --labels 'role=worker project=p id=i' p.i
}

attach_passes_a_callers_labels_through_on_an_undotted_name() {
  zmx_bare attach --labels role=worker dev
  assert_calls "$ZMX_STUB_LOG" 1
  assert_argv "$ZMX_STUB_LOG" 1 attach --labels role=worker dev
}

attach_births_the_session_in_its_own_scope() {
  zmx_on_path attach p.i nu
  assert_calls "$SD_STUB_LOG" 2
  assert_argv "$SD_STUB_LOG" 1 --user --scope --collect --quiet /bin/sh -c :
  assert_argv "$SD_STUB_LOG" 2 --user --scope --collect --quiet \
    "$work/bin/zmx-stub" attach --labels 'project=p id=i' p.i nu
}

attach_settles_for_bare_zmx_when_no_launcher_is_usable() {
  zmx_bare attach p.i nu
  assert_calls "$SD_STUB_LOG" 0
  assert_argv "$ZMX_STUB_LOG" 2 attach --labels 'project=p id=i' p.i nu
}

attach_settles_for_bare_zmx_when_the_user_manager_is_unreachable() {
  SD_STUB_FAIL=1 zmx_on_path attach p.i nu
  assert_status $? 0
  assert_calls "$ZMX_STUB_LOG" 2
  assert_argv "$ZMX_STUB_LOG" 2 attach --labels 'project=p id=i' p.i nu
}

attach_shows_a_failing_explicit_launcher() {
  local status=0
  SD_STUB_FAIL=1 ZMX_LAUNCHER=systemd-run zmx_on_path attach p.i nu 2> "$tmp/err" || status=$?
  assert_status "$status" 1
  assert_stderr 'Failed to connect'
  assert_no_session p.i
}

attach_with_no_name_is_zmxs_to_refuse() {
  local status=0
  zmx_bare attach 2> "$tmp/err" || status=$?
  assert_status "$status" 1
  assert_calls "$ZMX_STUB_LOG" 1
  assert_argv "$ZMX_STUB_LOG" 1 attach
  [ ! -s "$tmp/err" ]
}

attach_with_a_bare_labels_flag_is_zmxs_to_refuse() {
  local status=0
  zmx_bare attach --labels 2> "$tmp/err" || status=$?
  assert_status "$status" 1
  assert_calls "$ZMX_STUB_LOG" 1
  assert_argv "$ZMX_STUB_LOG" 1 attach --labels
  [ ! -s "$tmp/err" ]
}

attach_launcher_can_be_switched_off_explicitly() {
  ZMX_LAUNCHER='' zmx_on_path attach p.i nu
  assert_calls "$SD_STUB_LOG" 0
  assert_argv "$ZMX_STUB_LOG" 2 attach --labels 'project=p id=i' p.i nu
}

attach_launcher_is_data() {
  ZMX_LAUNCHER='systemd-run --user' zmx_on_path attach p.i nu
  assert_argv "$SD_STUB_LOG" 1 --user \
    "$work/bin/zmx-stub" attach --labels 'project=p id=i' p.i nu
}

attach_folds_an_unsafe_character_into_the_label() {
  zmx_bare attach 'p.a b'
  assert_argv "$ZMX_STUB_LOG" 2 attach --labels 'project=p id=a-b' 'p.a b'
}

attach_keeps_the_case_of_the_name() {
  zmx_bare attach Zmux.Tests
  assert_argv "$ZMX_STUB_LOG" 2 attach --labels 'project=Zmux id=Tests' Zmux.Tests
}

attach_refuses_a_name_with_an_empty_part() {
  local status=0
  zmx_bare attach p. 2>/dev/null || status=$?
  assert_status "$status" 2
  zmx_bare attach .hidden 2>/dev/null || status=$?
  assert_status "$status" 2
  assert_no_session p.
  assert_no_session .hidden
}

attach_refuses_a_name_with_two_dots() {
  local status=0
  zmx_bare attach my.repo.1 2>"$tmp/err" || status=$?
  assert_status "$status" 2
  assert_stderr 'my.repo.1'
  assert_no_session my.repo.1
}

attach_reaches_an_existing_session_it_would_not_create() {
  have_session my.repo.1
  zmx_bare attach my.repo.1 nu
  assert_argv "$ZMX_STUB_LOG" 2 attach my.repo.1 nu
}

# --- run -------------------------------------------------------------------

run_brackets_the_dispatch_with_state() {
  have_session p.i
  zmx_bare run p.i make test
  assert_calls "$ZMX_STUB_LOG" 4
  assert_argv "$ZMX_STUB_LOG" 1 ls --short
  assert_argv "$ZMX_STUB_LOG" 2 set p.i state=working
  assert_argv "$ZMX_STUB_LOG" 3 run p.i make test
  assert_argv "$ZMX_STUB_LOG" 4 set p.i state=done
}

run_exits_with_the_task_code_and_records_failure() {
  have_session p.i
  export ZMX_STUB_RUN_EXIT=7
  local status=0
  zmx_bare run p.i false >/dev/null || status=$?
  assert_status "$status" 7
  assert_argv "$ZMX_STUB_LOG" 4 set p.i state=failed
}

# pi's exec timeout signals the direct child alone, then closes its pipes: the
# caller is released, the task runs on, and the client's status means nothing.
terminate_the_caller_mid_run() {
  have_session p.i
  mkfifo "$work/hold"
  export ZMX_STUB_RUN_HOLD=$work/hold ZMX_STUB_RUN_EXIT=141
  PATH=$work/bare "$work/bin/zmx" run p.i make test >/dev/null &
  local pid=$! status=0
  await_call "$ZMX_STUB_LOG" 3
  kill -TERM "$pid"
  wait "$pid" || status=$?
  assert_status "$status" 143
  assert_calls "$ZMX_STUB_LOG" 3
  printf 'go\n' > "$work/hold"
  await_call "$ZMX_STUB_LOG" 5
  assert_argv "$ZMX_STUB_LOG" 4 wait p.i
}

run_records_the_task_result_after_the_caller_is_terminated() {
  terminate_the_caller_mid_run
  assert_argv "$ZMX_STUB_LOG" 5 set p.i state=done
}

run_records_a_task_failure_after_the_caller_is_terminated() {
  export ZMX_STUB_WAIT_EXIT=7
  terminate_the_caller_mid_run
  assert_argv "$ZMX_STUB_LOG" 5 set p.i state=failed
}

run_leaves_working_in_place_when_it_detaches() {
  have_session p.i
  zmx_bare run p.i -d sleep 9
  assert_calls "$ZMX_STUB_LOG" 3
  assert_argv "$ZMX_STUB_LOG" 2 set p.i state=working
  assert_argv "$ZMX_STUB_LOG" 3 run p.i -d sleep 9
}

run_creates_a_labelled_session_and_keeps_the_output_clean() {
  local out
  : > "$tmp/err"
  out=$(zmx_bare run p.i make 2> "$tmp/err")
  [ "$out" = task-output ] || {
    printf '  stdout: wanted "task-output", got "%s"\n' "$out"
    return 1
  }
  if [ -s "$tmp/err" ]; then
    printf '  stderr: %s\n' "$(cat "$tmp/err")"
    return 1
  fi
  assert_calls "$ZMX_STUB_LOG" 6
  assert_argv "$ZMX_STUB_LOG" 2 run p.i true
  assert_argv "$ZMX_STUB_LOG" 3 set p.i 'project=p id=i'
  assert_argv "$ZMX_STUB_LOG" 4 set p.i state=working
  assert_argv "$ZMX_STUB_LOG" 5 run p.i make
  assert_argv "$ZMX_STUB_LOG" 6 set p.i state=done
}

run_creates_an_undotted_session_without_labels() {
  zmx_bare run dev make
  assert_calls "$ZMX_STUB_LOG" 5
  assert_argv "$ZMX_STUB_LOG" 2 run dev true
  assert_argv "$ZMX_STUB_LOG" 3 set dev state=working
  assert_argv "$ZMX_STUB_LOG" 4 run dev make
  assert_argv "$ZMX_STUB_LOG" 5 set dev state=done
}

run_sees_detach_anywhere_in_the_command() {
  have_session p.i
  zmx_bare run p.i make -d > /dev/null
  assert_calls "$ZMX_STUB_LOG" 3
  assert_argv "$ZMX_STUB_LOG" 2 set p.i state=working
  assert_argv "$ZMX_STUB_LOG" 3 run p.i make -d
}

run_writes_no_state_on_a_usage_error() {
  local status=0
  have_session p.i
  zmx_bare run p.i 2> "$tmp/err" || status=$?
  assert_status "$status" 1
  assert_stderr 'requires a command'
  assert_calls "$ZMX_STUB_LOG" 2
  assert_argv "$ZMX_STUB_LOG" 2 run p.i
}

run_labels_a_session_even_on_a_usage_error() {
  local status=0
  zmx_bare run p.i 2> /dev/null || status=$?
  assert_status "$status" 1
  assert_argv "$ZMX_STUB_LOG" 3 set p.i 'project=p id=i'
}

run_brackets_a_command_piped_on_stdin() {
  have_session p.i
  printf 'make\n' | zmx_bare run p.i > /dev/null
  assert_calls "$ZMX_STUB_LOG" 4
  assert_argv "$ZMX_STUB_LOG" 2 set p.i state=working
  assert_argv "$ZMX_STUB_LOG" 4 set p.i state=done
}

run_with_no_name_is_zmxs_to_refuse() {
  zmx_bare run > /dev/null 2>&1 || true
  assert_calls "$ZMX_STUB_LOG" 1
  assert_argv "$ZMX_STUB_LOG" 1 run
}

run_creates_a_labelled_session_when_the_user_manager_is_unreachable() {
  SD_STUB_FAIL=1 zmx_on_path run p.i make > /dev/null
  assert_status $? 0
  assert_argv "$ZMX_STUB_LOG" 2 run p.i true
  assert_argv "$ZMX_STUB_LOG" 3 set p.i 'project=p id=i'
}

run_refuses_to_dispatch_when_creation_fails() {
  local status=0
  SD_STUB_FAIL=1 ZMX_LAUNCHER=systemd-run zmx_on_path run p.i make 2> "$tmp/err" || status=$?
  assert_status "$status" 1
  assert_stderr 'Failed to connect'
  assert_no_session p.i
}

run_refuses_to_dispatch_when_labelling_fails() {
  local status=0
  ZMX_STUB_SET_FAIL=1 zmx_bare run p.i make 2> "$tmp/err" || status=$?
  assert_status "$status" 1
  assert_stderr 'p.i'
  assert_no_dispatch p.i make
}

run_resolves_a_dot_to_the_current_session() {
  have_session p.i
  export ZMX_SESSION=p.i
  zmx_bare run . make
  assert_calls "$ZMX_STUB_LOG" 4
  assert_argv "$ZMX_STUB_LOG" 2 set p.i state=working
  assert_argv "$ZMX_STUB_LOG" 3 run p.i make
}

run_refuses_a_name_with_two_dots() {
  local status=0
  zmx_bare run my.repo.1 make 2>/dev/null || status=$?
  assert_status "$status" 2
  assert_no_session my.repo.1
  assert_no_dispatch my.repo.1 make
}

run_reaches_an_existing_session_it_would_not_create() {
  have_session my.repo.1
  zmx_bare run my.repo.1 make
  assert_argv "$ZMX_STUB_LOG" 3 set my.repo.1 state=working
  assert_argv "$ZMX_STUB_LOG" 4 run my.repo.1 make
}

run_refuses_a_dot_outside_a_session() {
  local status=0
  zmx_bare run . make 2>/dev/null || status=$?
  assert_status "$status" 2
  assert_calls "$ZMX_STUB_LOG" 0
}

# --- zmx-new ---------------------------------------------------------------

# The launcher's own listing, then the wrapper's, then the attach: reaching
# `attach --labels` proves it went through the wrapper.
assert_attached() {
  assert_calls "$ZMX_STUB_LOG" 3
  assert_argv "$ZMX_STUB_LOG" 1 ls --short
  assert_argv "$ZMX_STUB_LOG" 3 "$@"
  assert_calls "$HARNESS_STUB_LOG" 0
}

assert_ran_directly() {
  assert_calls "$ZMX_STUB_LOG" 0
  assert_argv "$HARNESS_STUB_LOG" 1 "$@"
}

new_starts_the_first_session_of_a_project() {
  new_on_a_tty "$(project_dir zmux .git)" "$work/bin/harness"
  assert_attached attach --labels 'project=zmux id=1' zmux.1 "$work/bin/harness"
}

new_numbers_one_above_the_highest() {
  have_session zmux.1
  have_session zmux.4
  have_session zmux.2
  new_on_a_tty "$(project_dir zmux .git)" "$work/bin/harness"
  assert_attached attach --labels 'project=zmux id=5' zmux.5 "$work/bin/harness"
}

new_counts_only_this_projects_numbers() {
  have_session zmux.tests
  have_session zmux2.9
  have_session other.7
  new_on_a_tty "$(project_dir zmux .git)" "$work/bin/harness"
  assert_attached attach --labels 'project=zmux id=1' zmux.1 "$work/bin/harness"
}

new_folds_dots_in_the_project() {
  have_session www_example.2
  new_on_a_tty "$(project_dir www.example .git)" "$work/bin/harness"
  assert_attached attach --labels 'project=www_example id=3' www_example.3 "$work/bin/harness"
}

new_names_the_project_from_a_subdirectory() {
  local dir
  dir=$(project_dir zmux .git)
  mkdir -p "$dir/pkgs/zmx"
  new_on_a_tty "$dir/pkgs/zmx" "$work/bin/harness"
  assert_attached attach --labels 'project=zmux id=1' zmux.1 "$work/bin/harness"
}

new_takes_every_marker_of_a_project() {
  local dir
  dir=$(project_dir flakes .project)
  mkdir -p "$dir/agents"
  new_on_a_tty "$dir/agents" "$work/bin/harness"
  assert_argv "$ZMX_STUB_LOG" 3 attach --labels 'project=flakes id=1' flakes.1 "$work/bin/harness"
}

new_treats_a_home_repository_as_no_project() {
  local dir
  dir=$(project_dir notes/daily)
  mkdir -p "$work/home/.git"
  new_on_a_tty "$dir" "$work/bin/harness"
  assert_attached attach --labels 'project=daily id=1' daily.1 "$work/bin/harness"
}

new_with_no_command_starts_a_shell_session() {
  new_off_a_tty "$(project_dir zmux .git)"
  assert_attached attach --labels 'project=zmux id=1' zmux.1
}

new_keeps_flags_for_the_harness() {
  new_on_a_tty "$(project_dir zmux .git)" "$work/bin/harness" --resume 'two words'
  assert_attached attach --labels 'project=zmux id=1' zmux.1 "$work/bin/harness" --resume 'two words'
}

new_runs_directly_inside_a_session() {
  ZMX_SESSION=zmux.1 new_on_a_tty "$(project_dir zmux .git)" "$work/bin/harness"
  assert_ran_directly
}

new_runs_directly_without_a_terminal() {
  new_off_a_tty "$(project_dir zmux .git)" "$work/bin/harness" --resume
  assert_ran_directly --resume
}

new_runs_a_subcommand_directly() {
  new_on_a_tty "$(project_dir zmux .git)" "$work/bin/harness" mcp list
  assert_ran_directly mcp list
}

new_runs_a_one_shot_flag_directly() {
  local flag dir
  dir=$(project_dir zmux .git)
  for flag in -p --print -v --version -h --help; do
    new_on_a_tty "$dir" "$work/bin/harness" --model opus "$flag"
    assert_ran_directly --model opus "$flag"
  done
}

new_keeps_the_status_of_a_direct_run() {
  local status=0
  HARNESS_STUB_EXIT=7 new_off_a_tty "$(project_dir zmux .git)" "$work/bin/harness" || status=$?
  assert_status "$status" 7
}

# --- escape hatches, aliases, pass-through ---------------------------------

raw_disables_every_rewrite() {
  ZMX_RAW=1 zmx_bare attach p.i nu
  assert_argv "$ZMX_STUB_LOG" 1 attach p.i nu
  ZMX_RAW=1 zmx_bare run p.i make
  assert_argv "$ZMX_STUB_LOG" 2 run p.i make
  assert_calls "$ZMX_STUB_LOG" 2
}

the_alias_attaches_with_labels() {
  zmx_bare a p.i nu
  assert_argv "$ZMX_STUB_LOG" 2 attach --labels 'project=p id=i' p.i nu
}

the_alias_dispatches_with_state() {
  have_session p.i
  zmx_bare r p.i make
  assert_argv "$ZMX_STUB_LOG" 2 set p.i state=working
  assert_argv "$ZMX_STUB_LOG" 3 run p.i make
}

every_other_verb_passes_through_byte_for_byte() {
  zmx_bare ls --short
  assert_argv "$ZMX_STUB_LOG" 1 ls --short
  zmx_bare kill a b --force
  assert_argv "$ZMX_STUB_LOG" 2 kill a b --force
  zmx_bare detach
  assert_argv "$ZMX_STUB_LOG" 3 detach
  zmx_bare
  assert_argv "$ZMX_STUB_LOG" 4
  assert_calls "$ZMX_STUB_LOG" 4
}

# --- runner ----------------------------------------------------------------

run_case() {
  local name=$1 case=$2
  : > "$tmp/log"
  if ! setup >> "$tmp/log" 2>&1; then
    printf 'FAIL %s (fixture)\n' "$name"
    sed 's/^/  /' "$tmp/log"
    failed=$((failed + 1))
    return
  fi
  # A plain statement: inside `if` or beside `||`, bash ignores set -e, and only
  # a case's last assertion would count.
  (set -e; "$case") < /dev/null >> "$tmp/log" 2>&1
  local status=$?
  if [ "$status" -eq 0 ]; then
    printf 'ok   %s\n' "$name"
    passed=$((passed + 1))
  else
    printf 'FAIL %s\n' "$name"
    sed 's/^/  /' "$tmp/log"
    failed=$((failed + 1))
  fi
}

passed=0
failed=0

run_case attach-names-and-labels attach_names_and_labels_at_creation
run_case attach-undotted attach_leaves_an_undotted_name_alone
run_case attach-existing attach_never_relabels_an_existing_session
run_case attach-caller-labels attach_keeps_a_callers_labels_and_adds_its_own
run_case attach-caller-labels-undotted attach_passes_a_callers_labels_through_on_an_undotted_name
run_case attach-scope attach_births_the_session_in_its_own_scope
run_case attach-bare-fallback attach_settles_for_bare_zmx_when_no_launcher_is_usable
run_case attach-no-user-manager attach_settles_for_bare_zmx_when_the_user_manager_is_unreachable
run_case attach-launcher-fails attach_shows_a_failing_explicit_launcher
run_case attach-no-name attach_with_no_name_is_zmxs_to_refuse
run_case attach-bare-labels attach_with_a_bare_labels_flag_is_zmxs_to_refuse
run_case attach-launcher-empty attach_launcher_can_be_switched_off_explicitly
run_case attach-launcher-data attach_launcher_is_data
run_case attach-sanitise-char attach_folds_an_unsafe_character_into_the_label
run_case attach-keeps-case attach_keeps_the_case_of_the_name
run_case attach-empty-part attach_refuses_a_name_with_an_empty_part
run_case attach-two-dots attach_refuses_a_name_with_two_dots
run_case attach-two-dots-existing attach_reaches_an_existing_session_it_would_not_create
run_case run-brackets run_brackets_the_dispatch_with_state
run_case run-failure run_exits_with_the_task_code_and_records_failure
run_case run-terminated run_records_the_task_result_after_the_caller_is_terminated
run_case run-terminated-failure run_records_a_task_failure_after_the_caller_is_terminated
run_case run-detached run_leaves_working_in_place_when_it_detaches
run_case run-creates run_creates_a_labelled_session_and_keeps_the_output_clean
run_case run-creates-undotted run_creates_an_undotted_session_without_labels
run_case run-detach-anywhere run_sees_detach_anywhere_in_the_command
run_case run-usage-error run_writes_no_state_on_a_usage_error
run_case run-usage-error-labels run_labels_a_session_even_on_a_usage_error
run_case run-piped run_brackets_a_command_piped_on_stdin
run_case run-no-name run_with_no_name_is_zmxs_to_refuse
run_case run-no-user-manager run_creates_a_labelled_session_when_the_user_manager_is_unreachable
run_case run-creation-fails run_refuses_to_dispatch_when_creation_fails
run_case run-labelling-fails run_refuses_to_dispatch_when_labelling_fails
run_case run-dot run_resolves_a_dot_to_the_current_session
run_case run-two-dots run_refuses_a_name_with_two_dots
run_case run-two-dots-existing run_reaches_an_existing_session_it_would_not_create
run_case run-dot-refused run_refuses_a_dot_outside_a_session
run_case new-first new_starts_the_first_session_of_a_project
run_case new-highest new_numbers_one_above_the_highest
run_case new-this-project new_counts_only_this_projects_numbers
run_case new-folds-dots new_folds_dots_in_the_project
run_case new-subdirectory new_names_the_project_from_a_subdirectory
run_case new-markers new_takes_every_marker_of_a_project
run_case new-home-repo new_treats_a_home_repository_as_no_project
run_case new-no-command new_with_no_command_starts_a_shell_session
run_case new-flags new_keeps_flags_for_the_harness
run_case new-in-session new_runs_directly_inside_a_session
run_case new-no-terminal new_runs_directly_without_a_terminal
run_case new-subcommand new_runs_a_subcommand_directly
run_case new-one-shot new_runs_a_one_shot_flag_directly
run_case new-direct-status new_keeps_the_status_of_a_direct_run
run_case raw raw_disables_every_rewrite
run_case alias-attach the_alias_attaches_with_labels
run_case alias-run the_alias_dispatches_with_state
run_case pass-through every_other_verb_passes_through_byte_for_byte

printf '\n%s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
