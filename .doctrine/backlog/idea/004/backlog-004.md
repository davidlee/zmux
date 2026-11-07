# IDE-004: Read Codex's own state reports instead of hooks

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

Codex's TUI reports its own state to the terminal over OSC 7501: `state=idle:app=codex`,
`working`, `done`, and `blocked:app=codex:kind=permission` (EVD-015). That last one came only at a
human's dialog, and stayed `working` under `auto_review`, so it is more accurate than the hooks,
which leave dialogs out for that reason.

Nothing can read it today: zmx keeps no trace of OSC 7501 (EVD-008). Something would have to watch
the session's output, most likely a change upstream in zmx.

Reading it might also remove the need for `codex --no-daemon`, since the TUI writes these reports
to its own terminal whichever server it uses. That is inferred: they were seen only without the
daemon.

The obstacle is ADR-002: state is written by the party that knows, and nothing watches. Codex does
know, but a reader in zmx is a watcher, so this needs that rule revisiting, or a small relay that
counts as the harness's own. It also serves only harnesses that emit these reports.

Related: IMP-006, IMP-009, EVD-008, EVD-015, ADR-002.
