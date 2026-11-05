# IMP-002: Cut Emacs and zsh over to the wrapper

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

Migrated from smut `tk-elisp-cutover`, which keeps the acceptance criteria and the
file list (`smut r tk-elisp-cutover -i -s -l 3`).

The surviving plugin lives in `~/.config/emacs`. It composes `<project>.<id>`, folds
dots in the project to `_` as zp does, and keeps the old copy's treatment of leading
dots and unsafe characters. Delete `emacs/` and `DL_ZMX_ELISP` here, and `za` in
`~/.config/zsh`. Old `P-ID` sessions stay reachable through `my/zmx-switch`.

## Why the fold matters more now

The wrapper now refuses a name with more than one dot. Until this lands,
`emacs/dl-zmx.el` does not fold, so a project such as `my.repo` gets the wrapper's
refusal in its buffer rather than a session. The copy on the host composes
`<project>-<id>`, so it is not affected.
