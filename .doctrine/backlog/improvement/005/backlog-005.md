# IMP-005: Write the Claude state plugin

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

Migrated from smut `d-harness-state`; `README.md` says "Claude's plugin comes later".

Pi has its plugin (IMP-004, `harness/pi/zmx-state.ts`). Claude Code has none, so a Claude
session in zmx advertises nothing.

As for pi, when `ZMX_SESSION` is set, the plugin writes that session's `state` as the
harness waits on a human and as it resumes. It runs in the harness and does not depend on
pi-zmx. Only an interactive session should write, so a delegate can't mark its parent
blocked (EVD-006 records this for pi).

The operator expects this one to break regularly, so it stays tiny and carries no weight
in the design. Which Claude Code hooks mark "waiting on a human" is not yet established.

Claude sets the terminal title itself, and a session running it has no shell for IMP-008's
prompt hook. So the same hooks should set the title along with `state` when waiting and done
(operator, 2026-11-07).

Related: IMP-006 (Codex), IMP-008 (tab bar).
