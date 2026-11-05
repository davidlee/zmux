`VOCABULARY.md` is the contract. Token rules are observed in EVD-009.

## Changed from the source

- Smut `d-vocab` rule 3, that only the session's own program writes state, is replaced by
  ADR-002.
- `zmux attach` never shipped: the wrapper derives the labels (ADR-003).
- It had the reader act only on `blocked`. The vocabulary now gives an ordering over all
  values.
- `role` arrived in 0.1.3, as a key pickers show and nothing reasons about.
- Lowercase now covers keys and `state` values only: `project` and `id` keep the name's case.
