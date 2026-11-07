# EVD-015: Codex hooks see every transition, and run under exec too

<!-- Knowledge record body — context, detail, links. The structured, queried
     fields live in the sister `record-NNN.toml`; this prose is free-form and is
     never structurally parsed (the storage rule). -->

## Method

A logging hook on nine events, in Codex 0.166.0 (npm) on `gpt-6-luna`, with zmx 0.8.1 and the
wrapper on PATH, on x86_64-linux, 2026-11-07. Scratch `CODEX_HOME` and `ZMX_DIR`; the operator
trusted the hook through `/hooks`. Each TUI ran under `zmx attach` under `script`, with prompts
sent through `zmx send`. The hook recorded its input keys, parents, the parent's stdout, and
whether it could write to `/dev/tty`, write to that stdout, and run `zmx set`.

| Case | Hook events |
|---|---|
| TUI, one tool call | `SessionStart`, `UserPromptSubmit`, `PostToolUse`, `Stop` |
| TUI, Esc during a running tool | `UserPromptSubmit`, `Interrupt`; no `Stop` |
| TUI, dialog, `approvals_reviewer = "user"` | `PermissionRequest` at the dialog |
| The same, dialog declined with Esc | `Interrupt`; no `Stop`, nothing ran |
| TUI, `approvals_reviewer = "auto_review"`, reviewer approved | `PermissionRequest`, `PostToolUse`, `Stop`; no human was asked |
| TUI, subagent | subagent's `PostToolUse` has `agent_id`; main thread's has no such key |
| `codex exec`, stdout a pipe | all fire, `ZMX_SESSION` inherited |
| `codex exec` on a session's terminal | all fire, `zmx set` works, parent's stdout is the pty |

A scratch `CODEX_HOME` has no daemon, so the TUI above ran its own app-server. On the host's real
home, a bare `codex` connects to the shared app-server daemon, and hooks run there. Traced live,
2026-11-07:

| Launch | Hook's parent | Parent's stdout | `ZMX_SESSION` | Result |
|---|---|---|---|---|
| `codex`, real home | daemon, 0.167.0 | `/dev/null` | unset | writes nothing |
| `codex --no-daemon`, real home | TUI, 0.166.0 | the pty | set | `state=blocked`, and the title |

A hook's input doesn't name the TUI behind a turn, so the daemon can't serve one zmx session
without `--no-daemon`. `zsh -lc` kept neither form from reaching the script, with or without
`exec`. Upstream's `$SHELL -lc` launch is Codex's reading of the source (RV-001), not observed.

Reaching the terminal, from a hook:

| Route | Observed |
|---|---|
| `/dev/tty` | fails, in the TUI too |
| `/proc/$PPID/fd/1` | reaches the client, and a client attaching later gets it replayed as OSC 2 |
| `zmx print` | reaches an attached client; EVD-012 says it bypasses the PTY, so no replay is expected. Replay not tested |

Other findings:

- Codex's own titles overwrite ours: `Run echo hi | work` followed the hook's title.
  `-c 'tui.terminal_title=[]'` stops them, and the hook's title was then the only one emitted.
  The docs' `null` has no TOML spelling.
- Codex emits OSC 7501 reports to the terminal: `state=idle:app=codex`, `working`, `done`, and
  `blocked:app=codex:kind=permission`, the last only at a human's dialog. Under `auto_review` it
  stayed `working`. zmx keeps no trace of OSC 7501 (EVD-008), so nothing here can read them.
- `permission_mode` was `default` in each TUI and `bypassPermissions` under `exec`. The TUIs set
  `approval_policy` explicitly and `exec` did not, so this doesn't show the field tells them apart.
- Hooks don't run until trusted: without trust, a turn ran and the log stayed empty.

Not observed: a dialog approved by a human, an `auto_review` denial, a `codex exec` argv (the
process had gone), or whether a human's dialog behaves differently on `--no-daemon`. A title written through the parent's stdout was clean in the few writes
seen, but nothing rules out it landing inside a TUI frame.
