- `unset ZMX_SESSION` and set a scratch `ZMX_DIR`. The live namespace holds the operator's
  sessions, and agents may be running inside one. Keep the path short: it is a socket path.
- Give every probe a hard timeout. `echo data | zmx run NAME cat` hangs in zmx 0.8.1, its
  own help example.
- `pkgs.zmx` is the wrapper; the real binary is `pkgs.zmx-unwrapped`. The wrapper's
  `REAL_ZMX` line holds its path.
- A new failure mode for the argv tests goes in `tests/stubs/`: they assert argv against stubs.
- `/bin/sh` here is bash. Nothing runs the suite under dash routinely; `v0.1.1` passed
  there by rewriting the wrapper's shebang by hand.
