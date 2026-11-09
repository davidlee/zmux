# IMP-010: Show session state as an icon in zp

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

zp shows labels as trailing `key=value` text, so `state=blocked` is searchable but slow to
scan. zp is upstream, unforked (DEC-011), so the change goes upstream, and generic: zp should
not learn our vocabulary.

## Drafted upstream (not yet opened)

Fork `davidlee/zmx-picker`, clone `~/dev/zmx-picker` (remote `upstream` is
EarthmanMuons). PR bodies are drafted in `~/dev/zmx-picker/PR-*.md`, excluded from git.
Both branches are pushed to the fork; no PR is opened.

| branch | worktree | commit | what |
|---|---|---|---|
| `fix-exported-out` | `~/dev/zmx-picker` | `5cf37d9` | `local +x out` in `daemon_pid`: the bug CHR-003 worked around |
| `label-marks` | `~/dev/zmx-picker-marks` | `7421dbd` | `ZP_LABEL_MARKS='state=working=● state=blocked=◐'`, a mark column ahead of the name |

`ZP_LABEL_MARKS`: space-separated `key=value=mark` entries, split at the last `=`. Marks are
concatenated in the map's order and padded by characters. Labels still show and match. Unset,
the rows are byte-identical to today.

To run the suite on NixOS, replace `/bin/bash` in `tests/run.sh` (as `pkgs/zp` does) and put
`expect fzf gawk` on PATH.

## In use meanwhile (2026-11-09)

Fork branch `zmux` (`80f879c`) is `fix-exported-out` plus `label-marks`. `pkgs/zp` pins it
by commit; its suite runs without the `env -u out` workaround. The wrapper sets a default
`ZP_LABEL_MARKS` for the four `state` values (`--set-default`, so a caller's own value,
even empty, wins). DEC-011 and the README say so.

## When upstream releases

- Point `pkgs/zp` back at the upstream tag, and update DEC-011 and the README.
- If upstream rejects or reshapes either change, decide whether to keep the fork.

## Open

- `state` is intent; zmx's `ended`/`exit_code` are the fact (README: show both). zmx 0.8.1's
  `list` carries no `ended`, so a mark can only reflect the label for now. Revisit once zmx
  lists it: an ended session's `working` should not look live.
