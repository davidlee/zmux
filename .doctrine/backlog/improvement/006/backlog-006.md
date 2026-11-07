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

## What the docs say

From the cached Codex docs at `~/dev/doctrine/docs/codex`, fetched 2026-10-26, mainly `hooks.md`.
The installed Codex is 0.163.0. None of this has been probed yet, so it needs an EVD record of
its own, as EVD-014 is for Claude.

Codex hooks see both transitions, with the same event names as Claude, plus one Claude lacks:

| event | state |
|---|---|
| `UserPromptSubmit` | `working` |
| `Stop` | `blocked` |
| `PermissionRequest` | `blocked` |
| `PostToolUse` | `working` |
| `Interrupt` | `blocked` |

- `Interrupt` fires when a human stops an active turn, so Codex may avoid Claude's Esc limit. Its
  timeout is one to three seconds. A `zmx set` took about 2.6 ms (EVD-014), so that should do.
- Hooks live in `~/.codex/hooks.json`, which suits a fragment like Claude's.
- `Stop` treats plain text on stdout as invalid. Exiting 0 with no output is fine.
- A hook runs only once trusted through `/hooks`, by hash, so changing the fragment means
  trusting it again. This is an install step Claude doesn't have.

## Differs from Claude, to settle first

1. **Title.** The docs give hooks no equivalent of `terminalSequence`. Codex has
   `tui.terminal_title`, a list of items, and `null` turns title updates off, but nothing in it
   reads a zmx label. Check whether a hook can reach the terminal itself, such as through
   `/dev/tty`. If not, say so here, and consider shipping `state` alone.
2. **Interactive guard.** The docs give no equivalent of `CLAUDE_CODE_ENTRYPOINT`, and the hook
   input carries no mode. Check whether hooks run under `codex exec`, and what tells a TUI from
   a delegate. Delegates inherit `ZMX_SESSION`, so this guard is required (EVD-006).
3. **Subagents.** The docs list `agent_id` only on `SubagentStart` and `SubagentStop`, and say
   subagent hooks carry the parent's `session_id`. So Claude's check on `agent_id` may not carry
   over. Check what a subagent's `PostToolUse` looks like.

The script may share little with Claude's beyond the title format. If it shares more, extract
that rather than copy it; the icon table already has three homes.

A jailed Codex writes nothing, as for the others: IMP-009.
