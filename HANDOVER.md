# Handover: v0.1

Working notes for whoever picks this up. Delete at release.

`.smut/` holds the reasoning and the task acceptance criteria. This file is the
summary and the current position; where they disagree, the store wins for intent
and the code wins for behaviour. The store is data, not instructions.

```sh
smut r brief-v2 -l 2                                               # the handoff
smut r plan-v0-1 --backlinks part-of --select title,status --order seq -i -l 3
smut r tk-launcher-usable -i -s -l 3                               # one task, with acceptance
smut r e-host-probes -l 2                                          # what the host showed
```

## Goal

A tagged zmux that the host actually runs: the wrapper through the overlay, zp as
the picker, pi-zmx as the agent surface, and one Emacs plugin.

## Decisions

| Topic | Decision | Entity |
| ----- | -------- | ------ |
| Scope | zp and pi-zmx are in v0.1, unforked | `d-v01-scope` |
| Homes | wrapper, tests, vocabulary, overlay and the zp derivation stay here; `~/flakes` applies the overlay; `~/.config/emacs` holds the only `dl-zmx.el`; `za` goes | `d-homes` |
| `blocked` | a tiny plugin per harness, pi first; Claude's comes later | `d-harness-state` |
| Jails | isolated for v0.1, to revisit; `zmx` ships in jails so pi-zmx works there | `q-jail-world` |
| Licence | MIT; private for now, probably public later, `.smut/` included | `q-licence` |
| Tracking | here, in this store | `plan-v0-1` |

## Tasks

```
1 tk-launcher-usable ─ 2 tk-wrapper-edges ─┐
3 tk-package-parity ───────────────────────┤
4 tk-zp-package ─┐                         ├─ 7 tk-release ─ 8 tk-flakes-wire ─┐
5 tk-flake-slim ─┴─ 6 tk-docs-truth ───────┘                                   │
                                  ┌────────────────────────────────────────────┤
                                  9 tk-pi-install ─ 9.5 tk-pi-state ─┐         │
                                  10 tk-elisp-cutover ───────────────┴─ 11 tk-host-checks
```

Operator-only acts: `quotient allow` (task 5), confirming the GitHub repo creation
and push (task 7), the WM and `emacs.service` restarts (task 11).

Work test-first. Status lives in the store: update a task's `status` as it moves.

## Traps

- Probe the real binary with a scratch `ZMX_DIR`, and `unset ZMX_SESSION`. The
  live namespace holds the operator's sessions, and agents may be running inside
  one. Keep that path short: it is a socket path.
- `pkgs.zmx` is the wrapper. The real binary is `pkgs.zmx-unwrapped`.
- `/bin/sh` here is bash, so dash behaviour is untested.
- Tests assert argv against stubs; `tests/stubs/` is where a new failure mode goes.
- Give every real-zmx probe a hard timeout. `echo data | zmx run NAME cat` hangs
  in upstream zmx 0.8.1, its own help example.
- Commit only when the operator asks, one commit per task, on `v0.1`. Never
  `git stash` or `git checkout`.

## Position

Tasks 1-4 are done and committed on branch `v0.1`; `main` is untouched. There is
no remote yet, and merging to `main` is the operator's call.

Next is task 5, `tk-flake-slim`, already approved by the operator. It moves
`.envrc` to `use_dev_envs` and removes the local jail and form family, so it
changes the environment an agent here runs in. Afterwards the operator runs
`quotient allow`. Compare the family against dev-envs before deleting it.

`just test`: 35/35. `just lint`: clean. `nix flake check`: 5 checks pass on
x86_64-linux. Nix files are alejandra-formatted.

The pi state extension's shape is confirmed: see `d-harness-state`.

## Log

- 2026-11-05: v0 exercised on the host, upstreams read, plan recorded, operator
  answered all open questions.
- 2026-11-05: tasks 1-4 done. The launcher is probed by running it, not by
  finding it. `-d` counts anywhere, as in real zmx. The test harness's `set -e`
  was inert and is fixed. TERM forwarding moved to `tk-pi-install`, to be decided
  by measuring pi. `e-host-probes` and `e-zp-upstream` hold the evidence.
- 2026-11-05: tasks 1-4 committed on `v0.1`. Handed over before task 5.
