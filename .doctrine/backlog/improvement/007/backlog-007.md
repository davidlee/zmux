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

Done: this repo on `main` (f54164b), nix-config pinning it at the root and in agents, the
shorthands, the zsh functions, and `zmx-new` in `features/terminal.nix`.

1. `just home-switch`. Until then `claude` and `codex` find no `zmx-new` in a new shell.
2. `just forms` here: `dev-tools` gained `util-linux`.
3. Migrate the 10 flakes outside dev-envs that carry their own `jcl`, or leave them. Not
   a second sharing mechanism.

`script -qefc` in the tests is util-linux's syntax, so `wrapper-tests` on aarch64-darwin
is unchecked (CHR-001).
