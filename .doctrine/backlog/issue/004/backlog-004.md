# ISS-004: zmx-new with no command nests inside a session

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

`zmx-new` with a command already ran it directly inside a session. With no command it
fell through to `zmx attach <project>.<n>`. Real zmx 1.0.1, probed in a scratch
`ZMX_DIR` with `ZMX_SESSION` set, prints `Error: cannot connect to session "probe.1":
FileNotFound`, exits 1 and creates nothing. The caller stays in the outer session, and
an `exit` meant for the new one ends it (reported by the operator; the probe is the
evidence for the mechanism).

Fixed: with no command and `ZMX_SESSION` set, `zmx-new` prints
`zmx-new: already in session <name>` on stderr and exits 1, before calling zmx. `zx`
inherits it. Test: `new_refuses_a_shell_session_inside_a_session`.
