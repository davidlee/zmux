# IMP-007: Start agents in a session without remembering to

An agent started outside zmx doesn't survive a window manager restart, and nothing
reminds the operator. So the usual ways of starting one go through a session by default.

## Shape

`zmx-new <command...>` composes `<project>.<n>` and attaches, running the command in the
session. It is a caller of the wrapper, so ADR-003 is untouched. It lives in this repo
because zsh and dev-envs both need it (operator, 2026-11-06, extending DEC-011).

- `claude` and `codex` become zsh functions over it. The operator chose shadowing over
  new names: a new name is one more thing to remember.
- `shorthand` in `~/flakes/dev-envs/flake.nix` starts `jcl`, `jcx`, `jpi` and `jsh`
  through it, which covers every `use_dev_envs` project with no per-project change.
- `zx` calls it and drops its own numbering.

The launcher reads the harness's argv, so a shorthand's baked-in flags sit behind a
script of their own. Otherwise `--dangerously-skip-permissions` would count as the
first argument and `jcl mcp list` would land in a session.

## Evidence (real zmx, scratch namespace, 2026-11-06)

- The command inherits the caller's environment and working directory.
- A second attach to a live session joins it and drops its command, without a word.
- The session ends with the command. Exit 3 reached the client as 0.
- A command that exits at once loses its output.
- Attaching from inside a session ran nothing and exited 0. The session named in
  `ZMX_SESSION` was gone by the next listing; the cause is not established.
- `jailed-claude --version` ran inside a session. A session surviving a restart with a
  jail in it has not been checked.

## Remaining

Live on the host (2026-11-06): the operator's `claude` in `/tmp/checky` landed in
`checky.1`, labelled `project=checky id=1`. Forms are accepted.

1. Check that a session with a jail in it survives a real WM restart.
2. Migrate the 10 flakes outside dev-envs that carry their own `jcl`, or leave them. Not
   a second sharing mechanism.

   retrograde is the pilot: edited, uncommitted, `jcl` goes through `zmx-new` and `just
   check` behaves the same in the new shell and a jail as before (2 vitest failures in
   `srd_threshold_parity`, also on the old shell). `devEnv` has no way to bind a path, so
   the boilerplate docker socket bind, `exposePostgres` and their env went with the jails.
   retrograde references none of them; check each project that carries the same lines.
   The operator doesn't want `d` or `sdr` aliases, so no project needs step 4 for those.

`script -qefc` in the tests is util-linux's syntax, so `wrapper-tests` on aarch64-darwin
is unchecked (CHR-001).
