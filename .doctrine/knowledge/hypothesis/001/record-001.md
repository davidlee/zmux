The mechanism is complete: `ZMX_SESSION` gives a program its own name, and every reader sees the
label in the same `zmx ls` parse.

- For: pi does this in `harness/pi/zmx-state.ts` (EVD-006).
- Against, or open: pi misses mid-run dialogs, and `blocked` outlives pi (ISS-001).
- Untested: Claude and Codex (IMP-005, IMP-006).

Settle this once those plugins exist, and ISS-001 is decided.

## Changed from the source

Smut `h-status-label` named pi in a jail and codex as the test. Its cheapest experiment, wrapping
one real workflow, has been run for pi only.
