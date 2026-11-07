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

Scope (operator, 2026-11-07): what Claude got under IMP-005, so `state`, the terminal title, a
tested hook script under `harness/codex/`, and a README entry. Parity with `harness/claude/` is
the bar, except where Codex differs below.

## Findings

EVD-015 holds the probes, on 0.166.0 (npm), the target (operator, 2026-11-07).

| event | state |
|---|---|
| `UserPromptSubmit` | `working` |
| `Stop`, `Interrupt` | `blocked` |
| `PostToolUse` | `working` |
| `PermissionRequest` | to decide, below |

- `Interrupt` removes Claude's Esc limit: Esc fires it, and no `Stop`. Its timeout is limited to
  three seconds, so the fragment can't reuse Claude's 5. `Stop` wants no plain text on stdout.
- Subagents: Claude's check on `agent_id` carries over.
- Install: `~/.codex/hooks.json`, then trust through `/hooks`, again after each change to it.
- Launch: the TUI must run as `codex --no-daemon`. On the shared daemon, hooks have no session
  and no terminal, and nothing in their input names the TUI (EVD-015). The `codex` function in
  `~/.config/zsh/functions.zsh` adds the flag, only for the TUI, since a leading flag would hide a
  subcommand from `zmx-new`.
- Title: `/dev/tty` fails, but a hook can write to `/proc/$PPID/fd/1`, which replays to a later
  client. It needs `tui.terminal_title = []`, which ends Codex's own titles in every session. If
  it proves awkward, ship `state` alone (operator, 2026-11-07).

## Decided (operator, 2026-11-07)

1. **`PermissionRequest` is left out.** It fires under `auto_review` too, before the reviewer, so
   `blocked` would be false on the host's own setting. A human's dialog reads `working`.
2. **The guard is the parent's stdout being a terminal.** That rules out piped delegates, and the
   title needs it anyway. `codex exec` on a real terminal passes it, at worst leaving a stale
   `blocked`. That was accepted over parsing argv.
3. **The title ships.** `harness/advertise.sh` now holds the title and icons for both harnesses.

## Handback from IMP-009

Jailed state will go through a relay and a `zmx-state VALUE` command, which writes `working` or
`blocked` on the surrounding session, prints its labels, and exits 0 outside a session. So
`write_state` in `harness/advertise.sh` is the one place to change, and labels already come from
its output. When it lands, the `ZMX_SESSION` gates in the hooks move into `zmx-state`, and the
interactive gates stay.

## Known limits

- The hooks replace Codex's and Claude's own generated titles rather than wrapping them. The
  operator would prefer to keep them, but a hook can't see them, so that would take something
  between the program and the terminal.
- `/proc` makes this Linux only. Elsewhere the hook writes nothing.
- `command codex` uses the daemon and advertises nothing, silently.
- `--no-daemon` sessions don't share the background server.

A jailed Codex writes nothing, as for the others: IMP-009.
