# Changelog

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
