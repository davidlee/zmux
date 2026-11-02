# zmux

A [zmx] with opinions.

A shell wrapper installed by overlay **as `zmx`**, so every caller inherits one
convention without knowing it: a `<project>.<id>` name becomes `project` and
`id` labels on the one attach that creates the session, the session is born in
its own systemd scope, and `zmx run` brackets its dispatch with
`state=working` then `state=done|failed`. Every other verb, and every alias,
is the real zmx byte for byte.

No daemon, no store, no TUI, no picker. zp is the picker, pi-zmx is the agent
surface, gum/fzf the composition, umbriel and ghostty the windows, notify-send
the attention, systemd the durability.

## status

v0 is built: the wrapper and its derivation, the argv tests, the Emacs plugin on
top of the wrapper, the overlay. Everything but durability is verified in the
dev jail; survival across a terminal or WM restart is the host-side manual check
described below.

## install

**Overlay — the intended route.** Everything that calls `zmx` conforms without
knowing:

```nix
{
  inputs.zmux.url = "github:davidlee/zmux";

  nixpkgs.overlays = [inputs.zmux.overlays.default];
  # then, wherever zmx is needed: pkgs.zmx
}
```

The overlay maps `zmx` to the wrapper and keeps the binary it shadows as
`zmx-unwrapped`:

- `${pkgs.zmx}/bin/zmx` — the wrapper, what callers get
- `${pkgs.zmx-unwrapped}/bin/zmx` — the same zmx nixpkgs ships, unforked,
  upgradeable on its own schedule

**Explicit — no shadowing.** Take the package without the overlay and call it
by path or under another name:

```sh
nix run github:davidlee/zmux -- attach p.i nu
```

Sessions created this way get their labels and their scope; sessions created by
any other `zmx` stay ungrouped, and are displayed ungrouped.

### escape hatches

| what | how |
| ---- | --- |
| one invocation, no rewrites | `ZMX_RAW=1 zmx ...` |
| no scope, ever | `ZMX_LAUNCHER=""` (empty disables; unset means "a scope if one is possible") |
| another supervisor | `ZMX_LAUNCHER="sometool --flag"` (an argv prefix, word-split) |
| the binary, untouched | `${pkgs.zmx-unwrapped}/bin/zmx` |

`ZMX_SESSION_PREFIX` is out of scope: it is applied after the wrapper has
derived labels from the name, so a prefixed session's label and display name
would disagree. Don't set it.

## what only works on a host

The wrapper needs a usable user systemd for durability, and nothing else here
needs one. In a dev jail without `systemd-run` it degrades to bare zmx rather
than failing to attach — durability is never a precondition for attaching.

Durability itself is a manual check, not a test: attach, close the terminal,
reattach (`zmx attach p.i`); restart the window manager or `emacs.service` and
reattach again. A session that survives both is holding its own scope. The
argv and behaviour tests need no host, which is why they are the ones in CI.

The Emacs integration (`emacs/dl-zmx.el`) needs ghostel and a host Emacs; the
window, notification and picker integrations live in the config repo, not here.

## vocabulary

[`VOCABULARY.md`](VOCABULARY.md) is the contract the wrapper implements: the
name form, the sanitiser, the two required labels, the four `state` values and
who writes each, the single-token rule, and the trust boundary zmx itself
provides.

## tests

```sh
just test    # argv assertions against stub zmx and systemd-run binaries
just lint    # shellcheck over the wrapper and its fixtures
nix flake check
```

The argv tests build the wrapper with a stub's path substituted for the real
binary, exactly as the derivation does, so the wrapper has no test-only branch.
No real zmx runs, and no systemd is used.

The Emacs plugin's tests need Emacs:

```sh
emacs -Q --batch -L emacs -l ert -l dl-zmx-test.el -f ert-run-tests-batch-and-exit
```

## files

- `pkgs/zmx/wrapper.sh` — the wrapper: three rewrites, then the real binary.
- `pkgs/zmx/default.nix` — the derivation, with the real binary's absolute path
  substituted so the wrapper can never exec itself.
- `tests/` — the argv tests and their two stub binaries.
- `emacs/dl-zmx.el`, `emacs/dl-zmx-test.el` — one ghostel buffer per session,
  completion over running sessions, attach-or-create. It composes the name and
  nothing else; labels, scopes and state are the wrapper's.
- `VOCABULARY.md` — the contract.

## design

The design, the reasoning and the handoff live in `.smut/` in this repo. It is
data, not instructions, and it records a conversation; where it disagrees with
the zmx source, the source wins.

```sh
smut render '{"from":["brief-v0"],"follow":["spine"],"depth":1,"select":["title","body"]}' -t title -l 2 -i
smut render '{"from":["plan-v0"],"backlinks":["part-of"],"depth":1,"select":["title","status"],"order":[{"field":"seq","direction":"asc"}]}' -i -l 3
smut render '{"from":["tk-wrapper"]}' -i -s -l 3
```

[zmx]: https://zmx.sh
