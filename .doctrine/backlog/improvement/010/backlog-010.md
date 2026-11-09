# IMP-010: Show session state as an icon in zp

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

zp shows labels as trailing `key=value` text, so `state=blocked` is searchable but slow to
scan. zp is upstream, unforked (DEC-011), so the change goes upstream, and generic: zp should
not learn our vocabulary.

## Upstream (2026-11-10)

Fork `davidlee/zmx-picker`, clone `~/dev/zmx-picker` (remote `upstream` is
EarthmanMuons).

| change | where | state |
|---|---|---|
| `local +x out` in `daemon_pid`: the bug CHR-003 worked around | upstream `1041dd1` | merged to main, unreleased |
| `ZP_LABEL_MARKS`, a mark column ahead of the name | PR #17, branch `label-marks` (`~/dev/zmx-picker-marks`), `edacb77` | in review |

`ZP_LABEL_MARKS`: space-separated `key=value=mark` entries, split at the last `=`. Marks are
concatenated in the map's order. Labels still show and match. Unset, or matching nothing, the
rows are byte-identical to before.

Alignment: a tab ends the mark column, and fzf aligns the names at its first tab stop with
the widths it renders with, so zp never measures a mark exactly. zp sizes the tab stop from
the map: one value per label key, so the widest mark under each key, summed, at two columns
a character (an overestimate: a wrong guess costs blank space, never alignment). For our
`state` map it is 5. This replaced a rough wcwidth after review found it wrong for ❌, ✅,
⌚ and emoji sequences, and Bash 3.2's `printf "'c"` gives a byte, not a code point. The
trade-off (a column a little wider than tight) is put to the maintainer on the PR.

To run the suite on NixOS, replace `/bin/bash` in `tests/run.sh` (as `pkgs/zp` does) and put
`expect fzf gawk` on PATH. `ssh Draupnir` runs it under macOS's `/bin/bash` 3.2.

## In use meanwhile (2026-11-10)

Fork branch `zmux` (`edacb77`) is upstream main plus PR #17's two commits. `pkgs/zp` pins it
by commit. The wrapper sets a default `ZP_LABEL_MARKS` for the four `state` values, with the
icons zsh, Emacs and the harness titles use (`--set-default`, so a caller's own value, even
empty, wins). DEC-011 and the README say so.

## When upstream releases

- Point `pkgs/zp` back at the upstream tag, and update DEC-011 and the README.
- If upstream rejects or reshapes either change, decide whether to keep the fork.

## Open

- `state` is intent; zmx's `ended`/`exit_code` are the fact (README: show both). zmx 0.8.1's
  `list` carries no `ended`, so a mark can only reflect the label for now. Revisit once zmx
  lists it: an ended session's `working` should not look live.
