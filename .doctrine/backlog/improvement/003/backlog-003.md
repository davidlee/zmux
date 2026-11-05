# IMP-003: Show session purpose in the Emacs picker

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

Numbered sessions such as `docs.1` and `docs.2` don't say what they are for, and a
session can't be renamed: zmx has no rename verb and `name` is read-only. So the name
stays the session's identity, and a `role` label carries its purpose:

    zmx set docs.2 role=test-runner

zp needs no change: it shows every label beside a row and, per its README, filters
on them. The wrapper needs no change. The Emacs code lives in the config repo, in
`~/.config/emacs/apps/dl-zmx.el`; the vocabulary lives here.

## Emacs: the picker

`dl-zmx--annotation` shows project, clients and directory, and no other labels.

- Show the session's other labels as `key:value` pairs.
- If `role` is set, show it before those pairs, aligned across rows so it stands out.
- `zmx list` also prints built-in fields (`pid`, `cwd`, `created`, `clients`, `ended`,
  `exit_code`, `cmd`). Decide which count as labels here; zmx marks no difference.
- Annotations are display only, so `role` can't be searched as things stand. Decide
  whether it belongs in the candidate string.

## Emacs: entering an id

`my/zmx-project` already takes a typed id and completes running ones, bound to `z` in
`my-term-map`. Decide whether that is enough, or whether the `my/zmx-new` commands
should offer an id too.

Whatever enters an id must refuse a dot before attaching: the wrapper's refusal never
reaches a person through a ghostel buffer, which closes on exit (EVD-005). Emacs
ISS-013 did this for the existing commands.

## VOCABULARY.md

- Add `role` as a display convention: one token saying what a session is for. Pickers
  show it if present, and nothing reasons about it, so it stays freeform.
- Warn that `'role=test runner'` silently stores `role=test`. Use hyphens.
- Reword "where the two disagree, the labels are the truth". That holds for grouping
  and display, not addressing: every zmx verb selects by name, and none by label. The
  name is the address, and labels describe the session.
- Say that `project` and `id` are the wrapper's meaning, not zmx's: `zmx set` accepts
  any value for them, even `id=other.thing` on an undotted session. Readers treat them
  as claims.
- Warn readers filtering `zmx list` to match whole fields: `grep id=3` also matches
  `pid=3…`.

The README's naming section should follow: `id` for a purpose known at creation,
`role` for one that emerges later.

## Done

Decided by the operator:

- `role` goes in the candidate string, after the aligned name, so it can be searched.
- No built-in field counts as a label, except `exit_code` beside a `state`. Every session
  made through `zmx run` carries `ended`, so showing it everywhere would be noise. A
  `state` is shown with the fact beside it, as the vocabulary asks.
- `state` shows as a coloured icon in its own aligned column, not as a word.
- `my/zmx-project` is enough for entering an id, so `my/zmx-new` is unchanged.

The icons come from the operator's list, with the mapping chosen here: `●` done, `◐`
working, `◌` blocked, `⊘` failed, `·` absent, `*` any other value. `○` is unused. The
table is `dl-zmx--state-icons`, so changing it is one line each.

Probed on real zmx 0.8.1 with a scratch `ZMX_DIR`: `'role=test runner'` stores `role=test`
at rc 0, `id=other.thing` is accepted on an undotted session, and the picker read labels
from a real `zmx list`. Not seen in a live vertico frame, so glyph width in the operator's
font is unchecked.

`my/zmx-project` completes bare identifiers and still shows no role. The card scoped
`role` to the picker. Emacs has no command to set a `role`: `zmx set` is the way.
