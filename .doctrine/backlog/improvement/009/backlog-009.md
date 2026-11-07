# IMP-009: Relay state out of jails

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

A jailed agent can't advertise `state`. `jailed-claude` and friends run inside a host zmx
session, but the jail clears `ZMX_SESSION` and has no `/run/user/1000/zmx`, so `zmx set .` fails
and the hooks (IMP-005) and the pi extension (IMP-004) write nothing. Checked from inside `jsh`
on 2026-11-07 for Claude. For pi this is inferred: IMP-004 exercised its jail home on the host.

Binding the session's socket into the jail would work, but a zmx socket is a whole client: a
jailed agent could `zmx send` into the session. So the operator expects a dedicated socket
relay, which accepts one narrow message such as `state=<value>` for the session the jail was
started in (operator, 2026-11-07).

That needs changes in `~/flakes/dev-envs` and `agents/jailed-agents.nix`, which own the jail. The
jail's `~/.claude/settings.json` is a different file from the host's, so the hooks need installing
there too. The title reads labels with `zmx get`, so the relay must answer that as well, or the
script must build the title without them.

Related: IMP-005, IMP-004, IMP-006, ISS-001.
