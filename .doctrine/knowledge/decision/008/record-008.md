Where each piece lives: DEC-011.

## Changed from the source

- Smut `d-surfaces` spoke of a core with verbs. The core is the wrapper, and there is no `zmux`
  verb (DEC-005).
- It said the core never names systemd. The wrapper's default launcher does name
  `systemd-run`; `ZMX_LAUNCHER` replaces it, and the wrapper falls back to none.
- `harness/pi/` lives in this repo, but the wrapper does not know about it.


Superseded by ADR-003, since this rule must be in mind during design. Doctrine refuses a supersede
edge across families, so the record is this line and a `governed_by` edge.
