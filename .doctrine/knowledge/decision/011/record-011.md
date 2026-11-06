`README.md` § integrations lists each location with a link.

- zp is a derivation of the upstream release, in `pkgs/zp`, unforked.
- pi-zmx is a pi package pinned in pi's host and jail `settings.json`.
  Both homes pin a fork, by commit, because upstream reports a timed-out `zmx_run` as a
  success. The fork fixes that bug; the convention needs no fork, since pi-zmx calls whichever
  `zmx` is on PATH.
- Bump a consumer with `nix flake update zmux` in `~/flakes/agents`.

## Changed from the source

- Smut `d-homes` called this repo "the tagged product". Tags still exist, but consumers track
  `main` (nix-config `5944a7c3`, `facb86f4`).
- Smut `d-v01-scope` is folded in here. It said pi-zmx arrives unforked.


## Added since

`zmx-new`, the launcher, lives here too, in `pkgs/zmx-new`. zsh and dev-envs both need it,
so it has to be a package, and `~/flakes/agents` already pins this repo (IMP-007). The zsh
config keeps `zx`, and gains `claude` and `codex`.