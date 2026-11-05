- A session created without the wrapper stays unlabelled and ungrouped, which is correct.
- An existing session is never relabelled. zmx would allow it (`attach --labels` upserts,
  EVD-010), so this is a check the wrapper makes.
- `ZMX_SESSION_PREFIX` is applied after the wrapper computes labels, so label and name would
  disagree. It is out of scope (DEC-012).
- The launcher needs a usable user systemd session. Without one the wrapper falls back to bare
  zmx: failing to attach is worse than failing to be durable.
- Bracketing `run` adds zmx calls per dispatch. Each is a client connect and disconnect in the
  session log, and the label writes are visible to everyone.
- `blocked` can't be inferred: it comes from the harness that asks (DEC-009).

## Changed from the source

Smut `c-wrapper-limits` said labels are create-time only, which is false (EVD-010). It named
pi-zmx's attach tool as the `blocked` writer; that tool writes nothing.
