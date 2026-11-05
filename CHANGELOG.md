# Changelog

## Unreleased

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
