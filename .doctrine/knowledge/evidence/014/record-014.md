# EVD-014: Claude Code's Stop marks a finished turn, and only the cli entrypoint has a human behind it

<!-- Knowledge record body — context, detail, links. The structured, queried
     fields live in the sister `record-NNN.toml`; this prose is free-form and is
     never structurally parsed (the storage rule). -->

## Method

The hooks in `harness/claude/`, first as a plugin, in Claude Code 2.1.310 on Haiku, with zmx 0.8.1 and the wrapper on PATH, on
x86_64-linux, 2026-11-07, with a scratch `ZMX_DIR`. Loaded with `--plugin-dir`, then `--settings`, with
`--setting-sources project` so the operator's own hooks stayed out. Each session was created by
`zmx attach` under `script` and the client then killed, so the session ran as `zmx-new` starts one
and `zmx list` showed `clients=0`. Prompts went in through `zmx send`. A logging hook on every
relevant event recorded the order.

| Case | Observed |
|---|---|
| Prompt, then turn ends, detached | absent, `working`, `blocked` |
| Second prompt, detached | `blocked`, `working`, `blocked` |
| Dialog in default mode | `blocked` at the dialog, `working` after approval, `blocked` at `Stop` |
| `-p` in the session, starting from `working` | stays `working` |
| The same, guard removed from a copy | ends `blocked`, so the guard is what holds it |
| `-p`, direct and nested in a Claude session | `CLAUDE_CODE_ENTRYPOINT=sdk-cli` both times |
| Esc during a streamed response, empty input | no event in 70s, not even `idle_prompt`; stays `working` |
| Esc on a dialog | no event in the 5s watched, and no `Stop` |

Other findings:

- `PermissionRequest` fires with the dialog. `Notification` `permission_prompt` came 6s later.
- After approval, the first event is `PostToolUse`. So a long approved tool reads `blocked`.
- `SubagentStop` fires after `Stop` for Claude's internal prompt-suggestion agent. Nothing can
  key on it to mean a subagent finished.
- `idle_prompt` fired 58s after a normal `Stop`, so it adds nothing to `Stop`.
- `zmx set .` is resolved by real zmx from `ZMX_SESSION`, not by the wrapper, which passes `set`
  through. With it unset, or the session gone, it exits 1.
- `zmx set` took about 2.6 ms a call.

Titles, as raw bytes reaching a client under `script`:

| Case | Observed OSC titles |
|---|---|
| Hooks returning `terminalSequence`, Claude's titles on | ours, then Claude's `◐ Rain`, `✳ Rain` over each |
| `CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1`, from the environment | only ours |
| The same, from `env` in the `--settings` file | only ours |
| Turn ended while detached, client attaches later | that title, replayed as OSC 2 |

The operator confirmed the title in a real terminal on the host, 2026-11-07.

From inside a real jail started in a session (`jsh`): `ZMX_SESSION` is unset, `/run/user/1000/zmx`
is absent, and `~/.claude/settings.json` is a different file from the host's.

Not observed, inferred from the hooks reference: a background subagent's `PostToolUse` can fire
after the main `Stop`, and carries `agent_id`. `CLAUDE_CODE_ENTRYPOINT` is undocumented
in `env-vars.md`, so the guard rests on observation alone.
