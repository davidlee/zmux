Every larger idea, such as agents sharing a session, agents tagging each other or remote
attach, reduces to a namespace that a human and a program can both read. Under that reading
zmux is small on purpose, which is the rationale of ADR-001.

No test against a real agent workflow is recorded. Settle this from use: a need that labels and
existing readers can't answer refutes it, and reopens ADR-001.

## Changed from the source

Smut `h-shared-world` described zmux as naming, labels and a reader. zmux ships no reader of its
own: zp and Emacs read the labels. Smut `e-multiclient` read the multi-client claim from the
interface; smut `e-zmx-affordances` later verified `clients=2` (EVD-012).
