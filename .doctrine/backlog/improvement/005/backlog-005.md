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

## Sketch

`harness/claude/` holds `zmx-state.sh` and `settings.json`, a fragment mapping events to a
state. The operator chose writing files directly over a plugin (2026-11-07), so there is no
manifest or marketplace.

| event | state |
|---|---|
| `UserPromptSubmit` | `working` |
| `Stop`, `StopFailure` | `blocked` |
| `PermissionRequest` | `blocked` |
| `PostToolUse`, `PostToolUseFailure` | `working` |

- Blocked means the turn ended (operator, 2026-11-07). The dialog rows are for completeness,
  since the operator rarely uses manual permissions.
- A finished turn writes `blocked`, as pi does at its prompt. `done` and `failed` stay the
  dispatcher's.
- `PostToolUse` writes on every tool call, because a hook has no memory and nothing fires on
  approval. Each event is a `zmx set` and a `zmx get`, a few ms and a few log lines, which beats
  keeping a flag file.
- A subagent's tool event writes nothing, so a background agent can't undo `blocked`.
- Only `CLAUDE_CODE_ENTRYPOINT=cli` writes, so a `-p` delegate can't touch its parent.
- `Notification` isn't used: `permission_prompt` lags the dialog by 6s, and `idle_prompt` only
  repeats `Stop`.

## Title

Each write also returns `terminalSequence`, an OSC 0 title in `zmx-title`'s format:
`docs.1 | test-runner | ~/dev/docs | 🔔`. Hooks have no terminal, so Claude Code emits it.
The icon table now has a third home, after zsh and Emacs.

`CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1`, in the fragment's `env`, is required: without it Claude
overwrites the title at once (EVD-014). It also ends generated session titles and Claude's
status reports to the terminal, in every host session, not only those in zmx.

## Install

Live on the host since 2026-11-07. `~/.claude/hooks/zmx-state.sh` links to this checkout, so a
change here reaches running sessions. `settings.json` is merged into `~/.claude/settings.json`,
which no repo owns, so a change to the fragment needs merging again.

## Known limits

- A turn ended with Esc fires no hook, so it reads `working` until the next prompt.
- A long tool approved at a dialog reads `blocked` until it finishes.
- `blocked` stays after Claude quits, as for pi (ISS-001). In a `zmx-new` session the session
  ends with Claude, so the label goes too.
- Until the first prompt there is no title of ours, and Claude no longer sets one.

## Evidence

EVD-014 holds the probes, and the operator confirmed the title in a real terminal
(2026-11-07). `tests/claude-state.test.ts` runs the commands `settings.json`
registers, under a scratch HOME, against a fake `zmx`, in `just test` and the `harness-tests`
flake check.

## Remaining

A jailed Claude writes nothing: IMP-009.
