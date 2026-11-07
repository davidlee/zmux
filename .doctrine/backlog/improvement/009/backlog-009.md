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

## Scope, 2026-11-07

The relay is `flakes:IMP-070`: ADR-001 rules out a server here, so the listener, the socket bind,
the jail's `zmx-state`, the jail's Claude hooks and pi's pin all live there. The relay is one more
caller writing a label, as zsh's title hook and the harness hooks are, so ADR-001 is not at odds
with it (operator, 2026-11-07).

This item keeps:

- A host `zmx-state VALUE` that writes `state` on the session around it and prints its labels. It
  exits 0 outside a session. The jail's has the same name and contract, so harnesses don't know
  they are jailed.
- Claude's hook and pi's extension move onto it, and their `ZMX_SESSION` gates move with it. Pi
  passes the session name itself in `zmx set`, so its write path changes, not just the command.
- A release first: `flakes:IMP-070` bumps its zmux input and pi's pin to it.
- The README's jail row, and a line in its Claude paragraph.

Values from a harness are `working` and `blocked` only.

Packaging: the jail's `zmx-state` is on PATH beside `commonPkgs`, which carries the `zmx` package
(`flakes:IMP-070`). Ship the host one so it can't shadow the jail's: a separate package, kept out of
`commonPkgs`. The jail's prints `zmx get` output as is: space-separated, no trailing newline.

## Progress, 2026-11-07

Done here: `pkgs.zmx-state`, and the three harnesses write through it. `advertise.sh` stays: it
owns the title and calls `zmx-state`, so it did not become it. `just test`, `just lint` and
`nix flake check` pass (x86_64-linux). Checked against the real zmx in a scratch `ZMX_DIR`: labels
print space-separated with no trailing newline, `done` is refused, and no session or a dead one
prints nothing and exits 0.

Choices:

- Nothing printed means nothing written, and `advertise` shows no title then. So RV-001's F-3
  (a failed label read keeps the title) moved into `zmx-state`, which prints `state=VALUE` when a
  write stood and the read did not. The jail's prints nothing there, so a jailed title is skipped.
- `zmx` comes from the caller's PATH, for the relay's reason: the session's daemon is the host's.
- No `timeout` in the host's: each harness already limits its hook.
- A jail has no `ZMX_SESSION`, so a session with no `project` label drops the name from its title.

Not yet observed: any of this in a real jail. Remaining, in `flakes:IMP-070`:

- A host needs `pkgs.zmx-state` on PATH. Until then the host's hooks, linked to this checkout,
  write nothing. Pi is pinned, so it changes only when bumped.
- The jail needs `harness/` whole, as the hook finds `advertise.sh` beside itself.
- Codex's hooks are not in the jail's home, nor on `flakes:IMP-070`'s list.
