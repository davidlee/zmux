# IMP-001: Install pi-zmx in both homes

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

Migrated from smut `tk-pi-install`, which keeps the acceptance criteria. `tk-pi-state`
follows this item.

## Sketch

1. Pin `npm:@deevus/pi-zmx@0.1.1` in `~/.pi/agent/settings.json` (done).
2. Decide how `zmx` reaches jails, then install in `~/agent_home/.pi/agent/settings.json`.
3. Decide how the wrapper handles TERM, then build it test-first.

## Evidence, 2026-11-06 (pi 1.4.0, zmx 0.8.1, scratch `ZMX_DIR`)

- **Load:** with `zmx` present, all six tools and `/zmx` register.
- **Dotted session:** host pi on the gateway ran `zmx_run` with `pismoke.one`. The
  session got `project=pismoke id=one`, `state=done`, and the output came back.
  `zp --candidates` lists a session of that name with its label column; that row came
  from a wrapper-created session with the same name, not the pi-created one.
- **No `zmx` on PATH:** `pi.exec` does not throw, so the stub branch never runs. The
  real tools and `/zmx` register, and every call fails. This corrects
  `e-pi-zmx-upstream`.
- **Signals:** on timeout `pi.exec` sends TERM to the direct child only, sends no KILL,
  and resolves only when that child exits.
- **Timeout against the wrapper:** `pi.exec` resolved at 2.1s with
  `{code: 0, killed: true}`. The task carried on, its client orphaned, and ended with
  `exit_code=0`, but `state=working` stuck. A control run without the timeout ended
  `state=done`.

## Findings

- **Stale state (ours):** a timed-out run leaves `state=working` for good.
- **False success (upstream):** `pi-zmx` reads `code`, not `killed`, so by its source
  `zmx_run` reports success on a timeout while the task runs. Inferred from the source
  and the measured result; not observed through the tool. No wrapper change can fix
  this, because `pi.exec` reports `code: 0` either way.
- **A plain `trap` does not work:** sh defers the trap until the foreground child ends,
  so a trapping wrapper holds `pi.exec` until the task finishes (8s against a 1s
  timeout).

## Jails

Jail home `~/agent_home` is shared by every project, and a jail's PATH is `commonPkgs`
plus that project's `dev-tools`. `zmx` is in neither for projects other than this one,
so installing there now gives those jails six dead tools. The `pox` jail uses
`~/.pi/agent` with the host's tools, so it has `zmx`, and its `/run/user` tmpfs keeps
its sessions separate.

## Decisions, 2026-11-06 (operator)

- **Jails:** add `zmx` to `commonPkgs` in `~/flakes/agents`.
- **TERM:** probe the background approach. Probing found something simpler: a
  foreground subshell, in `aa71845`. TERM kills only the outer shell, so stdin and
  SIGINT are unchanged and no background job exists. Once the caller is gone the
  client dies on its closed pipes, so the subshell takes the result from `zmx wait`.
  Real pi timeouts recorded `done` for exit 0 and `failed` for exit 7. 37 tests pass
  under bash and dash.
- **Upstream:** fix on the operator's fork, `~/.local/src/pi-zmx`, branch
  `fix/exec-failures`, then PR. Verified on host pi: with no `zmx`, stubs register and
  `/zmx` does not; a timed-out `zmx_run` reports an error.

## Remaining

Done on 2026-11-06: `v0.1.1` tagged and pushed; PR davidlee/pi-zmx#1 open against the
fork's `main`; host home pinned to fork commit `d6bae44`; `~/flakes` carries the wrapper
in `commonPkgs` and the `v0.1.1` bump (`flakes:IMP-068`), with gate and coverage green.

1. Operator: `just system-switch`, `just home-switch`, then relink forms and
   `quotient allow`.
2. Confirm `zmx` is the wrapper inside a jail.
3. Install `git:github.com/davidlee/pi-zmx@d6bae44153199131062f18069196a7596b30a677` in
   `~/agent_home/.pi/agent/settings.json`, then close this item and `flakes:IMP-068`.
