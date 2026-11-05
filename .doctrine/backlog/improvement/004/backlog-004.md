# IMP-004: Write the pi state extension

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

Migrated from smut `tk-pi-state`, which keeps the acceptance criteria; `d-harness-state`
holds the decision. `tk-host-checks` follows this item.

## Sketch

A pi extension, `harness/pi/zmx-state.ts`, independent of pi-zmx.

- `agent_settled` writes `state=blocked`: pi has no automatic work left and is at its
  prompt. `agent_end` is not idle: retries and queued messages can follow it.
- `agent_start` writes `state=working`, which replaces `blocked` on resume. Nothing
  deletes the label, as the vocabulary requires.
- Registers nothing without `ZMX_SESSION`.
- Only when `ctx.mode === "tui"`. `hasUI` is true in RPC mode, and print, JSON and RPC
  pis inherit `ZMX_SESSION` from a parent session: a delegate must not mark its
  parent blocked, and a `zmx run` dispatch keeps the wrapper's bracket.
- Writes only on a change, so retries cost nothing, and pi restarting over a stale
  `blocked` still replaces it.
- Writes run in order, one at a time: a slow `blocked` must not land after a later
  `working`. Handlers don't await them, and failures are dropped, so a hung `zmx` can't
  stall a run.

Delivery: a `pi` key in a root `package.json`, so both homes can pin this repo by commit
as they pin pi-zmx.

## Known limits

- A dialog raised mid-run by another extension (`ctx.ui.confirm`) is not seen: no event
  announces it.
- After pi quits, `blocked` stays until something replaces it. The vocabulary allows
  this: a stale state costs nothing.

## Evidence

EVD-006 holds the probes against real pi and zmx. `tests/zmx-state.test.ts` covers the
behaviour against a fake pi, in `just test` and in the `harness-tests` flake check.
`nodejs` joined `dev-tools` for that, so the forms need `just forms`.

## Outcome, 2026-11-06

Both homes pin `git:github.com/davidlee/zmux@188fcfc`. A real TUI pi in a scratch session
reached `state=blocked` through each pin, with every other extension loaded. The jail home
was exercised on the host with `PI_CODING_AGENT_DIR`, not from inside a jail.

Left for the operator: `quotient allow` for the relinked forms. Until then, quotient calls
at this directory are refused with `form-unapproved`.

