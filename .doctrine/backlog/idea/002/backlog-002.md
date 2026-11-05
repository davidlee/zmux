# IDE-002: One project list for Emacs and zsh

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

Recorded for completeness; probably won't do.

DEC-010 says that if a project list is ever maintained, it must be one list for
the system. Today there are two sources: zsh's `active-projects` (zoxide, used by `zx`) and
Emacs' own project list. Emacs keeps its list for now, by that decision.

`active-projects` is a zsh function, so only zsh can call it. Sharing it would mean moving
it out of `~/.config/zsh/functions.zsh`.
