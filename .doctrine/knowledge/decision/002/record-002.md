Rules and examples: `VOCABULARY.md` § Name, `README.md`. DEC-001 still applies: the name is
convenience for humans, and labels are the truth.

`zmx kill 'ns*'` matches by prefix (reprobed 2026-11-06, zmx 0.8.1); without a star it matches
exactly (EVD-003).

## Changed from the source

- Smut `d-name-form` was marked "Proposed", but it shipped in 0.1.0.
- It folded dots inside a part to `-`, so `a.b.c` became `project=a id=b-c`. Since 0.1.2 the
  wrapper refuses that name (`derive` in `pkgs/zmx/wrapper.sh`).
- `project` and `id` keep the name's case, also since 0.1.2.
