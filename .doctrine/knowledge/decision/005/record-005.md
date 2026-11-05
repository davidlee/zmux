Rewrites:

- `attach` that creates: `project` and `id` ride the same call in `--labels`, and the client is
  exec'd through the launcher.
- `run`: creates the session if absent, labels it with `zmx set` because `run` takes no labels,
  then brackets the task with `state` (DEC-004), exiting with the task's own status.

The limits are CON-002. Observed behaviour behind the rewrites: EVD-010, EVD-013.

## Changed from the source

- Smut `d-wrapper` said the raw binary stays at `${pkgs.zmx}/bin/zmx`. That is the wrapper
  itself; the binary is `zmx-unwrapped` (DEC-007).
- "Labels are create-time only" is false: `--labels` is atomic on attach, not exclusive
  (EVD-010), and `do_run` labels with `zmx set`.
- It said pi-zmx needs no fork. It needs none to conform, but one is pinned for a bug
  (DEC-011).


Superseded by ADR-003, since this rule must be in mind during design. Doctrine refuses a supersede
edge across families, so the record is this line and a `governed_by` edge.
