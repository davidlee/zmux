# IDE-003: Give Claude a way to run commands in zmx sessions, as pi-zmx does for pi

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

pi gets more than `state` from zmx. pi-zmx gives its agent tools, such as `zmx_run` and
`zmx_wait`, that run commands in persistent sessions, so processes and env vars survive across
calls and a human can attach to one. Claude Code has no such tool here, and no skill or MCP
server for it on the host (checked 2026-11-07). The same goes for Codex.

Whether to close the gap is open (operator, 2026-11-07). Claude can already call `zmx` through
its shell, so the question is whether a tool would add enough over that: the timeout handling
that made the pi-zmx fork necessary, and a labelled session by default, are the likely gains.

Options, if it is worth doing: a skill that teaches the `zmx` commands, or an MCP server. A skill
is the smaller, and fits a harness that is expected to break often.

Related: IMP-005, IMP-006.
