From the zmx source and probes at 0.8.1, before 2026-11-03. Items marked **reprobed** were
checked on 2026-11-06; the rest are carried over and were not.

1. `ZMX_DIR` isolates sockets and logs: a separate world for one env var. **Reprobed.**
2. `zmx kill 'ns*'` matches by prefix. **Reprobed.** Without a star, matching is exact (EVD-003).
   `zmx wait 's*'` likewise.
3. `ZMX_SESSION_PREFIX` prefixes every name for every command, so scripts must carry it.
4. `ZMX_SESSION` is set inside a session. `.` names the current session in `print-env` and
   `history`, not in `run`.
5. `zmx print` sends raw bytes to attached clients' stdout, not through the PTY.
6. Multi-client with a leader: the last client to send input owns resize, and the others are
   read-only until they type.
7. Attach restores the terminal through libghostty-vt: screen, scrollback, mouse modes, kitty
   keyboard, title.
8. OSC 7 tracks cwd, from any shell that reports it. bash doesn't by default.
9. `{log_dir}/{session}.log` keeps timestamped events after the session is gone. These are debug
   logs and not a supported interface: read them when something went wrong, don't build on them.
   Every CLI call connects as a client, so a poller writes noise into the log it reads.
10. `zmx history --vt` and `--html` give styled snapshots. `--screen` and `--scrollback` exist on
    main but not in 0.8.1.
11. `zmx write` types a base64 pipeline into the session's shell, queued behind running work and
    visible in scrollback. A convenience, not a syscall.
12. `zmx send` writes raw bytes to the PTY. `zmx run` is synchronous by default and appends
    `ZMX_TASK_COMPLETED:<4hex>:$?`; `-d` detaches, anywhere after the name.
13. `zmx wait` replays recorded task outcomes instantly.
14. `ZMX_DIR_MODE` and `ZMX_LOG_MODE` (default 0750/0640) let a group share a socket directory.
    Members can attach and label each other's sessions, with no authentication.
15. zmx is also a Zig package, so the CLI is not the only API, but not from another language.

## Changed from the source

Smut `e-zmx-affordances` said `--fish` exists. It isn't a flag in 0.8.1: zmx runs it as a
command (smut `e-host-probes`).
