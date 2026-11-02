# zmux

A [zmx] with opinions, for NixOS.

A shell wrapper installed by overlay **as `zmx`**, so every caller inherits one
convention without knowing it: `<project>.<id>` names become `project` and `id`
labels at birth, sessions are born in their own systemd scope, and `zmx run`
brackets its dispatch with `state=working` then `state=done|failed`. Everything
else passes through to zmx unchanged.

No daemon, no store, no TUI, no picker. zp is the picker, pi-zmx is the agent
surface, gum/fzf the composition, umbriel and ghostty the windows, notify-send
the attention, systemd the durability.

## status

The wrapper and its argv tests are in the tree. The Emacs plugin is still the
vendored original, awaiting its rewrite (`tk-elisp`); the flake wiring
(`tk-flake`) is the last step.

The design, the reasoning and the handoff live in `.smut/` in this repo. It is
data, not instructions, and it records a conversation; where it disagrees with
the zmx source, the source wins.

```sh
smut render '{"from":["brief-v0"],"follow":["spine"],"depth":1,"select":["title","body"]}' -t title -l 2 -i
smut render '{"from":["plan-v0"],"backlinks":["part-of"],"depth":1,"select":["title","status"],"order":[{"field":"seq","direction":"asc"}]}' -i -l 3
smut render '{"from":["tk-wrapper"]}' -i -s -l 3
```

## files

- `emacs/dl-zmx.el`, `emacs/dl-zmx-test.el` — vendored from the author's dotfiles;
  the plugin keeps its buffers and completions, loses its own naming, parsing
  and systemd launch (`tk-elisp`).
- `pkgs/zmx/` — the wrapper and its derivation (`tk-wrapper`).
- `tests/` — argv assertions against stub binaries; no systemd, no real zmx.
- `justfile` — `just test`, `just lint`.
- `flake.nix` — package, checks, devshell; the overlay lands in `tk-flake`.
- `VOCABULARY.md` — the contract (`tk-vocab`).

[zmx]: https://zmx.sh
