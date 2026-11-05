# IDE-001: Support or refuse remote sessions

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

Migrated from smut `h-remote`. Open: support remote sessions, or refuse them. To be decided.

The hypothesis: zmx's control surface is one unix socket per session, and ssh can forward
a unix socket, so a remote session is `ssh -N -L` away. zmux would need no transport, and
the same labels and list would apply with the machine name as one more field.

Unverified:

- Whether zmx tolerates the latency and peer credentials of a forwarded socket.
- Whether forwarded socket paths collide with local ones. Both live in the same per-UID
  directory, so names would need a machine prefix.

Against: smut `q-lazy` listed remote machines over SSH among the candidate refusals.
