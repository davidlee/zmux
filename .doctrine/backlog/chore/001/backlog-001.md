# CHR-001: Check the kit on aarch64-darwin

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

Migrated from the smut records `brief-v2` and `tk-flakes-wire`; `README.md` still says "Not
yet checked: aarch64-darwin".

The flake declares `aarch64-darwin`, but everything so far ran on x86_64-linux. Check on
Draupnir:

- `pkgs.zmx` and `pkgs.zp` build. `just isolation` evaluates Draupnir's home, but evaluating
  is not building.
- The wrapper degrades to bare zmx, since there is no user systemd (`c-wrapper-limits`):
  attach works, and sessions get labels.

Update the README's status section with the result.
