# Review RV-001 — code-review of IMP-006

Adversarial-review ledger. Structured findings live in the sister
ledger toml; this prose companion carries the reviewer's framing.

## Brief

<!-- Pre-reading + lines of attack: what this review is probing, the invariants
     it must hold the subject to, and where the bodies are likely buried. Seeded
     at `review new`; the reviewer fills it before raising findings. -->

Full adversarial code-review pass by codex over the uncommitted IMP-006 diff,
shared advertiser, both shell hooks, hook fragments, fixtures, and Nix/Just
wiring. IMP-006's Decided entries are constraints, not questions to reopen.

Probe the parent's terminal gate across retained shells and non-terminal fd
types; unread blocked-event stdin and the three-second budget; bash/dash and
symlink sourcing; terminal/JSON injection through labels and cwd; Claude
compatibility; and whether the fixtures establish the claimed runtime behavior.
Use fake zmx and isolated processes only. No real Codex, live zmx, or user
configuration access. Write only this ledger; IMP-009 is outside the pass.

## Pass assessment (codex)

Revision required: F-1 and F-2 are major; F-3 is minor. These are open raises
for the responder, not dispositions or verified repairs. Each detail separates
the isolated reproduction from any inference about live runtime occurrence.

Validation: all 39 existing Node harness tests passed, and shellcheck passed
for both shell hooks and the shared advertiser. Isolated PTY/fake-zmx probes
covered retained command shells, explicit exec, large blocked-event input,
control characters in cwd, set-success/get-failure, and direct bash/dash
execution. Resolving an installed symlink and sourcing the shared file worked
under both shells. No real Codex or zmx session was run; no user configuration
was accessed. No Nix build or Darwin runtime verification was performed.

Candidates not raised:

- Unread blocked-event stdin did produce BrokenPipe in an explicit write-all
  surrogate, but that is insufficient to claim Codex fails. The targeted
  [Codex 0.166.0 runner](https://github.com/openai/codex/blob/rust-v0.166.0/codex-rs/hooks/src/engine/command_runner.rs#L293-L315)
  ignores BrokenPipe and times stdin writing concurrently with output capture
  and child completion. Its timeout path also owns process-tree cleanup.
  Thus neither a pre-timeout stdin deadlock nor a mandatory drain is established
  against this target. The fixture's timeout-number assertion alone does not
  prove runtime deadlines, and no live timeout behavior was claimed.
- Opening the gate fd read-write is an active open, not passive metadata
  inspection. Isolated regular-file, pipe, FIFO and Unix-socket stdout probes
  returned promptly with a false terminal test; sockets cannot be reopened this
  way. No harmful non-terminal side effect was demonstrated, so there is no
  separate finding about the open mode.
- Existing Claude control-character/JSON escaping weaknesses were reproduced
  but predate this diff; F-2 targets the new Codex raw-terminal emission.
- The omitted PermissionRequest hook, real-terminal codex exec behavior,
  Linux-only /proc dependency, and shipping titles remain settled constraints.

Flake/Just wiring was inspected: the new tests and shared fixture are included
in the harness check, util-linux supplies script, and the three shell files are
linted. These source checks and passing host tests do not constitute Nix build
or real hook integration proof. No durable records were written outside RV-001,
in keeping with the ledger-only scope.

## Verification pass (codex, 2026-11-07)

- **F-1 VERIFIED:** every registered Codex command now execs the hook, and the
  fixture exercises the shipped command through an EXIT-trap shell. Independent
  bash/dash probes through a symlink installation passed for all four events.
  Removing exec in a disposable copy makes six tests fail.
- **F-2 VERIFIED:** final-title filtering removes C0 controls and DEL across
  cwd, labels and fallback session names. Independent byte-level probes passed
  for both hooks under bash/dash, including every filesystem-representable C0
  byte in cwd and BEL/ESC/ST/DEL in the other fields. Removing the sanitizer in
  a disposable copy makes both new control-character regression tests fail.
- **F-3 VERIFIED:** a failed label read after a successful state write preserves
  the fallback title; failed writes still exit silently. Both shells passed
  the independent probe. Making get failure fatal in a disposable copy makes
  the new fallback regression test fail.

The unchanged current tree passes all 42 Node harness tests and focused
shellcheck. Mutation probes ran only in disposable copies; no implementation
or tests in this checkout were edited. Per-finding verification turns contain
the file/line evidence and precise checks.

F-1's amended attribution is accounted for: its retained-shell defect is a
verified failure mode, while the observed live incident is reported in EVD-015
as a shared-daemon environment/terminal problem resolved with --no-daemon.
The old response's claim that these were the same cause is superseded. The
amendment and updated EVD-015/IMP-006 were read directly; the reported live
trace was not independently rerun. No real Codex, Claude, zmx, user configuration,
Nix build, Darwin execution or three-second runtime deadline test was involved.

## Synthesis

**Overall:** acceptable within this review's scope.

**Synopsis:** all three findings are verified after independent reproductions
and regression-test sensitivity checks. The raiser's pass remains concluded,
and RV-001 reports done with no outstanding findings. This closes the review
findings, not IMP-006 itself or a live integration certification. The amended
daemon diagnosis is preserved separately from the retained-shell repair.
The settled launch/platform/permission/title limits remain in IMP-006 and
EVD-015. Durable verification evidence stays on this ledger under the user's
ledger-only boundary; no other harvest records were written.

**Haiku:**

Shell yields to the hook  
Stray escapes fall from the name  
The bell finds its home
