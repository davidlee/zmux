# CHR-003: Bump zp to upstream 0.5.0

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

Upstream zmx-picker tagged v0.5.0 on 2026-11-07. `pkgs/zp` was on 0.4.0. Still unforked
(DEC-011).

What 0.5.0 brings (its CHANGELOG): sessions zmx cannot reach, such as daemons from a zmx
older than 1.0, are listed as stale with the reason, and Ctrl-X kills their daemon; `file://`
cwds from zmx 1.0+ show as `~` paths. The host runs zmx 0.8.1, so only the first matters yet.

## Done

- Version and hash bumped.
- `lsof` and `procps` on the wrapper's PATH. 0.5.0 finds a stale daemon with `lsof`, and
  shows and finds it with `ps` and `pgrep`. `lsof` is guarded by `command -v`, so without
  it the feature would be silently absent rather than broken.
- `checkPhase` runs the suite under `env -u out`.

## Upstream bug found

`daemon_pid` declares `local out`. Bash keeps a local exported when the caller exports the
same name, and nix builders and devshells export `$out`. The whole lsof capture then rides
in the environment of `awk`; past the kernel's 128 KiB per-string limit, exec fails with
E2BIG. Upstream's "large lsof output" test hits it in the nix sandbox. Reproduced outside
nix: `export out=x; f(){ local out; out=$(seq 1 200000); awk 'BEGIN{}'; }; f` fails, and
passes under `env -i`. At runtime it needs a devshell and >128 KiB of lsof output, so it is
unlikely. Fix upstream (rename the variable) — to go in the zp fork's PR alongside the label
display hook; drop the `env -u out` once it lands.

## Verification

`nix build .#zp` (upstream suite passes), `nix flake check`, `just lint`, `just test`
(56 pass), `alejandra -c`.
