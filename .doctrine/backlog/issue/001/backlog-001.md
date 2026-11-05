# ISS-001: Pi's blocked misses mid-run dialogs and outlives pi

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

Two limits of `harness/pi/zmx-state.ts`, documented in `README.md` and not tracked until now.

- A dialog raised mid-run is not seen, so a pi waiting on a human there reads `working`.
- `blocked` stays after pi quits, so a finished session keeps asking for a human.

The second follows from the vocabulary: nothing deletes the label except a human arriving
(`d-state-writer`). Decide whether either is worth fixing or stays a documented limit.
IMP-005 and IMP-006 will meet the same two questions.
