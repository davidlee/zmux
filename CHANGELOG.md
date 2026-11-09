# Changelog

## Unreleased

### Changed

- `pkgs.zp`: zmx-picker 0.5.0. It lists sessions zmx cannot reach as stale, with the
  reason, and Ctrl-X stops their daemon. It now carries `lsof` and `procps` for that.

## 0.1.4 - 2026-11-07

### Added

- `zmx-new` runs a command in a new `<project>.<n>` session, or runs it directly where
  a session would lose its output or status. `pkgs.zmx-new`, through the overlay.
- `harness/claude/`: an interactive Claude Code in a session advertises `state=blocked`
  when its turn ends or a permission dialog opens, and `state=working` when it resumes,
  and sets the terminal title to match.
- `harness/codex/`: the same for an interactive Codex, except that a dialog reads
  `working`, since under `auto_review` no human is asked.
- `zmx-state VALUE` writes `working` or `blocked` on the session around it and prints
  its labels. `pkgs.zmx-state`, through the overlay.

### Changed

- The harnesses write through `zmx-state`, so a jail can advertise through its own
  (`flakes:IMP-070`). A host needs `pkgs.zmx-state` on PATH, or they write nothing.

## 0.1.3 - 2026-11-06

### Added

- `zx`, a zsh function in the config repo, starts a session in a project picked from
  zoxide.
- `harness/pi/zmx-state.ts`: an interactive pi in a session advertises `state=blocked`
  at its prompt and `state=working` when it resumes. `package.json` makes this repo a
  pi package, so a home can pin it by commit.

### Changed

- The vocabulary adds `role`, a display label for a purpose that emerges after the name
  was chosen. It says the name is the address and labels describe the session, and that
  `project` and `id` are the wrapper's meaning, not zmx's.

### Removed

- The Emacs plugin and `DL_ZMX_ELISP`. The only copy is now `apps/dl-zmx.el` in the
  Emacs config repo, which composes `<project>.<id>` and folds dots in the project.

## 0.1.2 - 2026-11-06

### Changed

- A name with more than one dot is refused when it would create a session, rather
  than grouped under whatever precedes the first dot. An existing session with such
  a name, or an empty part, stays reachable and unlabelled.
- `project` and `id` keep the case of the name. The vocabulary no longer asks for
  them in lowercase.

## 0.1.1 - 2026-11-06

### Fixed

- A caller terminated mid-run no longer leaves `state=working` for good. The state
  is written when the task ends, from `zmx wait`'s result, because the client's
  status means nothing once its caller's pipes have closed.

## 0.1.0 - 2026-11-05

First release: a shell wrapper installed by overlay as `zmx`.

### Added

- The wrapper: `project` and `id` labels from a `<project>.<id>` name, a systemd
  scope for each session it creates, and `state` around `zmx run`.
- The overlay, with the real binary kept as `zmx-unwrapped`.
- `pkgs.zp`: zmx-picker 0.4.0 from upstream, unforked, calling the wrapper.
- The contract in `VOCABULARY.md`, and argv tests against stub binaries.
- The Emacs plugin, `emacs/dl-zmx.el`.

### Host behaviour

- An unusable launcher falls back to bare zmx: the launcher is probed by running
  it, not by finding it.
- `-d` counts anywhere after the name, as in real zmx.
- `run` creates no session it could not label.
- The package ships what it shadows: completions and the version.

### Known limits

- Not yet checked: a real WM restart, an `emacs.service` restart, aarch64-darwin.
- A TERM sent to the wrapper mid-run leaves `state=working` and orphans the zmx
  client.
- `blocked` has no writer.
