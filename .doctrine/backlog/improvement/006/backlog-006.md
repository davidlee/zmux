# IMP-006: Write the Codex state plugin

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

Requested by the operator on 2026-11-06, extending DEC-009 (each harness gets a
tiny state plugin of its own) beyond pi and Claude.

The same contract as IMP-004 and IMP-005: with `ZMX_SESSION` set, an interactive session
writes `state=blocked` when it waits on a human and `state=working` when it resumes. It
does not depend on pi-zmx, and non-interactive runs leave the session alone.

Whether Codex offers a plugin or hook that sees both transitions is not yet established.
Check that first: if it only sees one, say so here before building.
