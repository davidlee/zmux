Checked on zmx 0.8.1, 2026-11-06. Pairs with [[mem.pattern.zmux.probing-real-zmx]].

- `zmx run NAME "a b"` escapes its arguments, so one string is one command name: it exits 127.
  Don't re-quote, split or join; pass argv, or a script file.
- `zmx run` types into the session's shell, so `history` echoes the command. To prove what a
  program printed, run it from a file, or grep hits the echo.
- `attach` needs a TTY (`script -qec`), and its command becomes the session's: `attach NAME true`
  ends the session at once, so nothing is left to inspect. Use `sleep`.
- `--labels` is one argv element and a repeat replaces; see EVD-010. A space in a value silently
  truncates it (EVD-009).
- `zmx run` creates an absent session, and takes no labels. It prints chatter to stdout.
- `ended` is the last task, not the session (EVD-001). Don't read it as dead.
- `zmx run` returns the task's status: keep it exactly, failures included.
- Every CLI call connects as a client and lands in the session log. Build no polling loops.
