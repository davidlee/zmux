@.doctrine/state/boot.md
If you have NOT seen `BOOT-SENTINEL: doctrine-governance-snapshot` anywhere in your context (system prompt or preceding messages), you MUST read the file referenced above now. If you HAVE seen it, you MUST NOT — the content is already in context. If that file does not exist, doctrine is not set up in this checkout: tell the user to install doctrine and run `doctrine install`.

- use a 'sketch then work direct from backlog' approach by default, not the full slice machinery.
- empirical probes are valuable - consider recording the findings as EVD records.

Before running anything against zmx:

- the live namespace holds the operator's sessions, and agents may be running inside
  one. Never touch it: `unset ZMX_SESSION`, use a short scratch `ZMX_DIR`, and give
  every probe a hard timeout. `mem.pattern.zmux.probing-real-zmx` has the detail.

Work outside this repo lives with the tool it belongs to: README's `integrations`
says where. A change to `dev-tools` needs `just forms`, and `quotient allow` is the
operator's act.
