## Method

Reprobed 2026-11-06, zmx 0.8.1, scratch `ZMX_DIR`, with `zmx set` and `zmx get`:

| input | result |
|---|---|
| `path=/tmp/x`, `colon=a:b` | refused, exit 1, naming the value |
| `'note=hello world'` | exit 0, stores `note=hello` |
| `note=` | removes the key |
| a 300-character value | stored |
| `Zed=1 alpha=2` | `get` prints `Zed=1 alpha=2`: ASCII order, uppercase first |

Not reprobed: `ZMX_SESSION` naming the session from inside. `harness/pi/zmx-state.ts` relies on
it, and EVD-006 and EVD-007 saw that working.

## Consequence

A stale `state=done` can't be told from a fresh one, and a label is a claim, not proof.
`VOCABULARY.md` § Tokens and § Trust carry the rules.
