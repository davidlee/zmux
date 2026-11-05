- `pi -p` hangs on an open stdin: give it `</dev/null`.
- `pi.exec` never throws here. A timeout resolves `{code: 0, killed: true}` after TERM to the
  direct child only, then its pipes close; a missing binary resolves `code: 1`.
- Models may batch tool calls in one turn, and pi runs them together. To test an order, ask
  for separate turns or drive `pi.exec` from a scratch extension.
- A delegate pi inherits `ZMX_SESSION`. Guard with `ctx.mode === "tui"`, not `ctx.hasUI`,
  which is true under RPC (EVD-006).
- To prove something reaches every jail, build `dev-envs` against its stub project. zmux's
  own jail proves nothing: its `dev-tools` carries `zmx` anyway.
