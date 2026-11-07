# IMP-008: Show session status in Ghostty's tab bar

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

A tmux-like status line for zmx, with no second multiplexer and with Ghostty's own
rendering and scrollback intact. Ghostty's bottom tab bar is the surface, and an OSC 0
title sequence (`printf '\e]0;STATUS\a'`) sets its label:

    zmux.3 | test-runner | ~/dev/zmux

## Shape

A zsh `precmd` hook of our own, in `~/.config/zsh` (operator, 2026-11-07). In a session it
reads the labels with `zmx get "$ZMX_SESSION"`, takes the directory from `$PWD`, and prints
OSC 0. Outside a session (`ZMX_SESSION` unset) it does nothing. A session with no `role`
omits that field.

It runs only at a prompt and then exits, so ADR-001's rule against a long-running process
isn't touched. Like `zx`, it is a caller in the zsh config, so this repo changes only if
the display earns a line in VOCABULARY.md.

## Done

Proof of concept, by the operator:

- OSC 0 sets the label.
- The label used to last only until the next prompt. `sleep` showed that prompt-time
  title updates were the cause, not continuous interference.
- `DISABLE_AUTO_TITLE=true` (`~/.config/zsh/env.zsh`) stops Oh My Zsh overwriting it, and
  `shell-integration-features = no-title` (`~/.config/ghostty/config.ghostty`) stops
  Ghostty. Both are in place. Other shell hooks are untouched.

## Evidence (real zmx, scratch namespace, 2026-11-07)

Clients ran under `script`, so these are bytes reaching a client, not a label seen in a
Ghostty tab.

- OSC 0 written inside a session reaches an attached client, and a later attach gets it
  again.
- `zmx print <name>` also delivers OSC 0, from outside the session, and a later attach gets
  that one instead of the earlier title.
- Output written before any client attaches didn't reach the client that then attached.
- `zmx get` took about 2 ms a call, on a session with one client attached.
- Each `zmx get` adds 2 lines to the session's log (`client connected`, `client
  disconnected`), so one per prompt is a small, steady growth.

## Hook

`zmx-title` in `~/.config/zsh/functions.zsh`, tested by `tests/zmx-title.zsh` there. The name
comes from the labels, falling back to `ZMX_SESSION` for a session with none or one `zmx get`
can't read.

A `state` label shows last, as the Emacs picker's icon (IMP-003): `●` done, `◐` working, `🔔`
blocked, `⊘` failed, `*` anything else. An absent `state` shows nothing. The table is
repeated in zsh and Emacs. The title is one string, so the icon comes last, not right-aligned.

Checked in the real zsh config, in a scratch session under `script`: it was the only title
writer, and `cd`, a new `role` and a removed `role` each showed at the next prompt. A shell
started before the change needs `exec zsh`.

Seen live by the operator (2026-11-07): `tmp.1 | /tmp | 🔔` in a Ghostty tab, and the bell in
the Emacs picker, with the row aligned.

## Limits

- A `role` set from elsewhere shows at the next prompt, and a long-running command leaves
  the label as it was.
- A program that sets the title holds it until the next prompt, when the hook wins.
- A session started with a command, as `zmx-new` starts `claude` and `codex` (IMP-007), has
  no shell, so the hook never runs there.

## Sessions without a shell

Claude sets the title itself. The fix is the Claude hooks that IMP-005 needs anyway to set
status when waiting and done, not this hook (operator, 2026-11-07). IMP-006 is the same
question for Codex.

Having `zmx-new` set a first title with `zmx print` would be a nicety, not the fix.

## To do

1. See what an Emacs ghostel client does with the title, since it attaches to the same
   sessions.

## Out of scope

- A background provider. ADR-001 needs superseding first, and a poller fills the session log.
- A GTK widget. Revisit only if tab-title formatting proves too restrictive.
