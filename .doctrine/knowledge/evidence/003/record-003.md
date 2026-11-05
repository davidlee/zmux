# EVD-003: zmx kill matches a session name exactly

<!-- Knowledge record body — context, detail, links. The structured, queried
     fields live in the sister `record-NNN.toml`; this prose is free-form and is
     never structurally parsed (the storage rule). -->

## Method

zmx 0.8.1, 2026-11-06, with a scratch `ZMX_DIR`. With `p.1`, `p.2` and `p.10` running,
`zmx kill p.1` printed `killed session p.1`, and `zmx ls --short` then listed `p.10` and
`p.2`. Prefix matching exists only when asked for, with a pattern such as `'p.*'`.
`my/zmx-kill` relies on this.
