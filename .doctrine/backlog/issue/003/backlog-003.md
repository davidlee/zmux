# ISS-003: zmx run hangs on piped stdin

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

Migrated from smut `e-host-probes`. Real zmx 0.8.1 hangs on `echo data | zmx run NAME cat`,
which is its own help example, and on `head -1`. The evidence attributes this to upstream,
not the wrapper. A piped command does reach a fresh session through the wrapper.

Not re-run since that probe; 0.8.1 is still the version in use. Re-check against
`zmx-unwrapped`, then report it to github.com/neurosnap/zmx if it still hangs.
