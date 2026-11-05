## Method

Reprobed 2026-11-06, zmx 0.8.1, scratch `ZMX_DIR`, attach under a pty.

1. `attach --labels 'project=P id=ID' q2 sleep 20` gave `id=ID project=P`.
2. `attach --labels a=1 --labels b=2 q4 sleep 20` gave `b=2`: the last one wins, so a wrapper
   mixing its labels with a caller's must build one token.
3. `attach --labels project=P id=ID q3 sleep 20`, unquoted, exits 1 and leaves no session. In
   the original probe, with no trailing command, it created a session named `id=ID`. Inferred:
   `id=ID` is taken as the name, and `q3 sleep 20` as its command, which fails at once.
4. `attach --labels c=3` onto an existing session added `c=3`. So "an existing session is never
   relabelled" is a check the wrapper makes, not a property of zmx.
5. `zmx run NAME true` creates the session and prints `session "NAME" created` plus the shell's
   echo and the task marker, so the wrapper's creation dispatch keeps that off the caller's
   output.
6. `zmx get missing` exits 1. `zmx ls --short` lists names, one per line.
7. `zmx run . true` fails outside a session, exit 1. Exit codes propagate (`sh -c 'exit 7'`
   gave 7). A detached run returns 0 at once with `command sent!`.
