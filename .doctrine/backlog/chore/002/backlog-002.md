# CHR-002: Migrate .smut into doctrine and delete it

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

`.smut/` (91 tracked JSON records) holds the design reasoning for v0 and v0.1. Its work is
finished: all 20 tasks are done and all questions closed. Doctrine's knowledge store holds
only EVD-001 to 007, so the reasoning exists nowhere else except git history. The operator
agreed on 2026-11-06 to migrate what is still live, repoint the references, then delete.

`.smut` is data, not authority: where it disagrees with the code or zmx source, those win.
Check each record against the code before promoting it, and record what it says now rather
than transcribing it.

## Disposition

Promote to decision records:

| Record | Note |
|---|---|
| `d-naming` | Labels are truth; its `<project>-<id>` form is replaced by `d-name-form` |
| `d-name-form` | Marked proposed, but shipped; `VOCABULARY.md` cites it |
| `d-vocab` | Rule 3 is replaced by `d-state-writer` |
| `d-state-writer` | |
| `d-wrapper` | Fold in `d-shadow-names`' correction on `zmx-unwrapped` |
| `d-install` | Same correction |
| `d-shadow-names` | |
| `d-surfaces` | Integration-blind core; drop the `zmux` verb wording |
| `d-harness-state` | IMP-005 and IMP-006 depend on it |
| `d-picker-jobs` | IDE-002 depends on it |
| `d-homes` | "Tagged product" is out of date: consumers now track `main` |
| `d-v01-scope` | Cited in source; may fold into `d-homes` |

Promote to constraint records: `c-cgroup`, `c-wrapper-limits`, `c-host-only`, `c-devjail`,
`c-json-intolerant`.

Promote as one decision record, the refusals: no daemon, reader, TUI, manifest, forks of zp
or pi-zmx, or `ZMX_SESSION_PREFIX` support (`q-lazy`, `q-manifest`, `brief-v0`). Remote
machines stay open under IDE-001.

Evidence: judge each record. Keep what is costly to rediscover, such as `e-status-channel`,
`e-zmx-ipc`, `e-zmx-affordances`, `e-labels-tokens`, `e-wrapper-probes`, `e-host-probes`. Skip
what EVD-001 to 007 or a memory already covers. `brief-v0`'s traps may suit a memory.

Hypotheses: `h-remote` is in IDE-001. Decide `h-status-label` and `h-shared-world`.

Leave in git history only: tasks, plans, briefs, the session record, closed questions, and
`d-kit`, `d-birth`, `d-adopt`, `d-shape`, `d-output`.

## References to repoint

- `README.md:270-278`, the design section, with its `smut r` commands. The operator is
  rewriting the README, so coordinate before editing it.
- `VOCABULARY.md:4-5`, and `AGENTS.md:5-7`.
- Comments citing smut ids in `flake.nix`, `pkgs/`, `tests/run-tests.sh`, `harness/pi/`.
- Doctrine records mentioning smut, including the `smut:` tags on backlog items. Keep the
  tags if they still help trace history.
- Outside this repo: `~/flakes` IMP-060, 067, 068 and Emacs slice 016. Those are records of
  finished work and probably need nothing; check, and don't edit them without asking.

## Done when

- Every promoted record exists, and source comments cite the new ids.
- No live reference to `.smut` or `smut r` remains, outside history.
- `just test` and `just lint` pass.
- The operator has confirmed the deletion, and one line in the README names the last commit
  that held `.smut`.

## Progress

2026-11-06. Promoted and committed (`2b9d966`). Repointed. `.smut` deleted on the operator's confirmation; last held at `42df5ed`.

- DEC-001 to 012, accepted by the operator 2026-11-06. `d-v01-scope` is
  folded into DEC-011.
- CON-001 to 005. EVD-008 to 013 (`e-zmx-logs` folded into EVD-012). HYP-001 from
  `h-status-label`, HYP-002 from `h-shared-world`. Memory `mem.pattern.zmux.zmx-cli-traps` from `brief-v0`'s traps.
- Evidence skipped as covered or historical: `e-zmx-lifecycle` (EVD-001), `e-zmx-surface`,
  `e-elisp`, `e-za`, `e-umbriel`, `e-prior-art`, `r-herdr`, `e-multiclient`,
  `e-flakes-systemd`, `e-zp-upstream`, `e-pi-zmx-upstream`.
- Records are tagged `smut:<id>`, as backlog items are.
- Repointed source comments, `VOCABULARY.md`, `AGENTS.md`, `README.md`, open backlog items and
  EVD-004. Resolved items IMP-001, 002 and 004 keep their smut mentions as history, as do
  "Migrated from smut" lines and `smut:` tags.
- ADR-001 to 003 replace DEC-012, DEC-004, and DEC-005 with DEC-008, as rules to hold in mind
  during design. Doctrine refuses cross-family supersede, and `related` or `supports` to an ADR:
  the DECs are `superseded` with a pointer line and `governed_by` edges, and evidence edges stay
  on the DECs.
