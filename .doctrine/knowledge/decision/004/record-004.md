`VOCABULARY.md` § state is the contract, including the ordering. EVD-001 records what `ended`
really reports.

## Changed from the source

- Smut `d-state-writer` named pi-zmx and the Emacs plugin as dispatchers. In shipped code the
  wrapper is the dispatcher (`do_run`), and `apps/dl-zmx.el` writes no state.
- Since 0.1.1 the outcome is written when the task ends, even if the caller was terminated.
- Clearing `blocked` on attach is permitted but not implemented: `do_attach` leaves `state`
  alone. ISS-001 covers what follows from that.
