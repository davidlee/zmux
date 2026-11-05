## Reasons

- **Daemon**: zmx has none to hold (CON-001). Survival comes from a scope per session.
- **Status protocol**: a label does the job, and OSC 7501 doesn't survive zmx (EVD-008).
- **Speaking zmx's socket**: an unstable ABI that belongs to someone else (EVD-011).
- **TUI, layout**: zp, Emacs, ghostty and umbriel already own those surfaces.
- **Manifest**: a second source of truth. Sessions are created on demand by name. For repeated
  setup, use a justfile target or a function calling attach N times. Revisit only if a real
  project needs sessions started in an order.
- **`ZMX_SESSION_PREFIX`**: applied after the wrapper computes labels, so label and name would
  disagree (CON-002).

## Not refused

Deferred: an MCP server, agent coordination beyond labels. Remote sessions stay open under
IDE-001.

## Changed from the source

- Smut `q-lazy` deferred the manifest while `q-manifest` settled against it; this record takes
  the later, stronger answer, with its revisit condition.
- `brief-v0` refused any picker. zp is now packaged and `zx` exists: the refusal that survives
  is a reader of our own.
- "No forks of pi-zmx" no longer holds as written: a fork is pinned for a bug (DEC-011).
- Smut `h-shared-world`, the legibility argument, is folded in as the rationale. It said to test
  this against the first real agent workflow; no such test is recorded.
