# EVD-006: pi's agent_settled marks the prompt, and only a TUI pi has a human behind it

<!-- Knowledge record body — context, detail, links. The structured, queried
     fields live in the sister `record-NNN.toml`; this prose is free-form and is
     never structurally parsed (the storage rule). -->

## Method

`harness/pi/zmx-state.ts` in pi 1.4.0 on `llm-gateway/deepseek-flash`, with zmx 0.8.1 and the
wrapper on PATH, on x86_64-linux, 2026-11-06, with a scratch `ZMX_DIR`. Each run used
`--no-extensions --no-session -e`. The TUI ran in a real session PTY, created by the
unwrapped `zmx run NAME -d pi ...`. Later prompts went in through `zmx send`.

| Case | Observed `state` |
|---|---|
| TUI, first prompt | absent, `working`, then `blocked` by about 4s |
| TUI, second prompt running `sleep 4` | `blocked`, `working`, `blocked` |
| `pi -p`, `ZMX_SESSION` set | absent throughout |
| `--mode json -p`, `ZMX_SESSION` set | absent; `agent_settled` was emitted |
| `--mode rpc`, `ZMX_SESSION` set | absent; `agent_settled` was emitted |
| TUI loaded by `-e <repo root>`, through `package.json` | `blocked` |

Inferred, not observed: `ctx.hasUI` is true under RPC. That comes from pi's
`docs/rpc-extension-ui.md`.

