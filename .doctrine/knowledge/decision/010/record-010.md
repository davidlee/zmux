## Why not ZP_ROOT

Measured 2026-11-06. zp scans each root to any depth, hidden and ignored paths included, with
no depth or exclude option. `~/dev` alone gave 346 hits. Roots listing only top-level repos
still gave 216 rows for 37 projects. A missing root is a hard exit 1. Fixing either means
forking zp (ADR-001).

Sources compared the same day: the `~/dev` glob (37 repos), Emacs' project list (36, with
`/tmp` entries), zoxide (48 after filtering), quotient's policy roots (17, a permissions list).

## What a project is

`active-projects` in `.config/zsh/functions.zsh` keeps zoxide directories holding a `.git`
directory, `.jj` or `.project`. It skips `$HOME`, Emacs' `elpa`, `/workspace` and any directory
whose `.git` is a file. `.project` is shared with project.el, and is how `~/flakes` qualifies.

IDE-002 proposes one project list for Emacs and zsh.

## Changed from the source

Smut `d-picker-jobs` said a project holds `.git` or `.project`. The function also takes `.jj`,
and excludes the paths above. "A small launcher of our own" became `zx`.
