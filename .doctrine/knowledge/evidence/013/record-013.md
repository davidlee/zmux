## Method

Sleipnir, 2026-11-05, zmx 0.8.1, scratch `ZMX_DIR`, real user systemd. Not repeated; each
finding was a small sample. The defects found then were fixed; what follows still describes the wrapper or the host.

## Observed

- A dotted `run` wrote labels, preserved exit 7 and set `state=failed`.
- SIGKILL of an attaching client: the session survived, in a scope distinct from the caller's.
- Three concurrent creates of one name labelled it once. One sample, not a proof.
- The launcher probe (`systemd-run --user --scope --collect --quiet /bin/sh -c :`) costs about
  5ms, on attach and session creation only.
- `systemd-run --user` succeeded with a stale `DBUS_SESSION_BUS_ADDRESS`, so that variable
  doesn't decide usability. With `XDG_RUNTIME_DIR` unusable, `systemd-run` is present and no
  user bus answers: this is why the wrapper probes the launcher rather than `command -v`.
- A piped command reaches a fresh session through the wrapper: the bootstrap doesn't swallow
  stdin.
- `zmx run NAME` with no command is a usage error, not a task.

The upstream hang on `echo data | zmx run NAME cat` is ISS-003. Terminating a wrapper mid-run
used to leave `state=working`; fixed in 0.1.1.
