# EVD-004: emacs.service PATH reaches the wrapper and systemd-run

<!-- Knowledge record body — context, detail, links. The structured, queried
     fields live in the sister `record-NNN.toml`; this prose is free-form and is
     never structurally parsed (the storage rule). -->

## Method

Inspection of the live process, 2026-11-06: `PATH` in `/proc/<pid>/environ` of
`emacs.service`'s main process, and `executable-find` through `emacsclient`. `zmx`
resolved to the wrapper in `~/.nix-profile/bin`, and `systemd-run` to
`/run/current-system/sw/bin`. This is why the plugin could drop `dl-zmx-launcher`:
the wrapper finds `systemd-run` through the process's `PATH`, not Emacs's `exec-path`.

## Not established

That a session started from Emacs is in its own scope, or survives an `emacs.service`
restart. Those are `tk-host-checks`. Confidence is medium because this is one host at
one moment, and the environment changes with the host configuration.
