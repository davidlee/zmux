# zmux

A [zmx] with opinions.

A shell wrapper installed by overlay **as `zmx`**, so every caller inherits one
convention without knowing it: a `<project>.<id>` name becomes `project` and
`id` labels when the wrapper creates the session, the session is born in its
own systemd scope, and `zmx run` brackets its dispatch with
`state=working` then `state=done|failed`. Every other verb, and every alias,
is the real zmx byte for byte.

No daemon, no store, no TUI, no picker. zp is the picker, [`zx`](#integrations) the
launcher, pi-zmx the agent surface, gum/fzf the composition, umbriel and ghostty the windows, notify-send
the attention, systemd the durability.

## opinions

- **A session is named `<project>.<id>`.** The dot is what zmx's own examples
  use, and what its prefix matching suits: `zmx kill 'zmux.*'`.
- **The name is convenience; labels are truth.** The wrapper reads the name once,
  at creation. After that, group by the labels and never parse the name again.
- **Ungrouped and honest beats grouped and wrong.** A session outside the
  convention gets no labels and is shown ungrouped. Nothing guesses its project,
  and the wrapper never relabels an existing session.
- **Refuse, don't rewrite.** The caller's name reaches zmx unchanged. A name with
  an empty part is refused, not repaired.
- **Conform without knowing.** Callers supply a name and nothing else. Labels,
  scope and state are the wrapper's.
- **`state` is intent, not fact.** It is what a dispatcher claimed. zmx's own
  `ended` and `exit_code` are the fact. Show both, and believe neither alone.
- **One fact, one home.** Never repeat `state` in the name, and never re-derive
  `project` from the name once the label exists.
- **Nothing watches.** Labels are written by whoever knows, at the moment they
  know. A stale label costs nothing.
- **Attaching beats durability.** With no usable scope the session still starts,
  as bare zmx.

## naming

This section is the summary. The contract is [`VOCABULARY.md`](VOCABULARY.md).

```
zmux.tests            the name, passed to zmx unchanged
──┬─ ──┬──
  │    └── id=tests        tells sessions in a project apart
  └─────── project=zmux    the repo's directory name, dots folded to _
```

A name holds one dot, and it is the separator. `project` is the unit of grouping. `id` is
either a number (`zmux.1`, the next one up) or a word saying what the session is
for (`zmux.tests`). Use `id` for a purpose known at creation. A session can't be renamed,
so a purpose that emerges later goes in a `role` label: `zmx set zmux.1 role=test-runner`.

What the wrapper does with a name when it creates a session:

| name | outcome |
| ---- | ------- |
| `zmux.tests` | `project=zmux id=tests` |
| `my_repo.1` | `project=my_repo id=1` |
| `zmux` | no labels: ungrouped, still scoped |
| `a b.c d` | `project=a-b id=c-d`: unsafe characters become `-` in the labels only |
| `Zmux.Tests` | `project=Zmux id=Tests`: case is kept |
| `my.repo.1` | refused, exit 2: more than one dot |
| `.hidden`, `p.`, `.` | refused, exit 2: a part is empty |

A project name that contains a dot has to be folded to `_` by the caller, before
the name is composed. An existing session with a refused name, such as one made
with `ZMX_RAW=1`, can still be reached, and stays unlabelled.

### who names sessions

| caller | name today | labels today | intended |
| ------ | ---------- | ------------ | -------- |
| zp, a repo row | `<repo>.<n>`: dots folded to `_`, `n` one above the highest in use | wrapper | no change. Repo rows need `ZP_ROOT` or path arguments, and the intended setup has neither, so this path is normally unused |
| zp, a typed name | the query as typed | wrapper, if dotted | no change. Type `zmux.tests`, not `tests` |
| `zx` | `<project>.<n>` for a project picked from zoxide, dots folded to `_`, `n` as zp's | wrapper | no change. This is the normal way to start a session |
| Emacs, a new terminal | `<project>.<n>`, as zp's. Outside a project, the directory's name stands in for `project` | wrapper | no change |
| Emacs, `my/zmx-project` | `<project>.<id>`, with an id you type | wrapper | no change |
| pi-zmx, default | the pi session name: lowercased, whitespace to `-`, anything else outside `[\w-]` stripped | none: it can't hold a dot | nothing planned |
| pi-zmx, `session` parameter | as given, such as `zmux.tests` | wrapper | nothing planned. Agents should pass one |
| `zmx attach` by hand | as given | wrapper, if dotted | no change |

## status

v0.1.3: the wrapper, its argv tests, the overlay, the zp package and the pi state
extension. See the [changelog](CHANGELOG.md). On an x86_64-linux host, sessions
from zp, Emacs and pi have survived an `emacs.service` restart and a WM restart, and
reattached. Not yet checked: aarch64-darwin.

## install

**Overlay — the intended route.** Everything that calls `zmx` conforms without
knowing:

```nix
{
  inputs.zmux.url = "github:davidlee/zmux";

  nixpkgs.overlays = [inputs.zmux.overlays.default];
  # then, wherever zmx is needed: pkgs.zmx, and pkgs.zp for the picker
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
needs one. Where `systemd-run` is absent or cannot reach a user manager, as in a
dev jail, it degrades to bare zmx rather than failing to attach: durability is
never a precondition for attaching.

Durability itself is a manual check, not a test: attach, close the terminal,
reattach (`zmx attach p.i`); restart the window manager or `emacs.service` and
reattach again. A session that survives both is holding its own scope. The argv
and behaviour tests need no host, so `nix flake check` runs them. There is no CI.

## integrations

zmux holds the wrapper, the zp package and the pi state extension. Everything else that
touches it lives with the tool it belongs to, in the operator's config repos:
[nix-config] (`~/flakes` is its `flakes/` directory) and [emacs-config].

| integration | where it lives |
| ----------- | -------------- |
| the zmux input | [`flakes/flake.nix`][nix-flake] |
| the overlay, applied | [`flakes/hosts.nix`][nix-hosts] |
| zp, installed | [`flakes/features/terminal.nix`][nix-terminal] |
| `zx`, `active-projects` | [`.config/zsh/functions.zsh`][zsh-functions] |
| Emacs | [`apps/dl-zmx.el`][emacs-zmx] |
| the wrapper in jails | `commonPkgs` in [`flakes/agents/jailed-agents.nix`][nix-jails] |
| pi-zmx | [a fork][pi-zmx-fork] of [`@deevus/pi-zmx`][pi-zmx], pinned in pi's [host][pi-host] and [jail][pi-jail] `settings.json` |
| `blocked` for pi | [`harness/pi/zmx-state.ts`](harness/pi/zmx-state.ts), here, pinned the same way |

- **zp** is packaged here from upstream, unforked, as `pkgs.zp`. Under the overlay
  its `zmx` is the wrapper, so its sessions get a scope, and labels when their
  names are dotted. See [who names sessions](#who-names-sessions).
- **`zx`** starts a session in an active project: pick one with fzf, and it attaches
  `<project>.<n>` from that directory. `active-projects` lists zoxide's project
  directories in frecency order. Both are zsh functions, so only zsh can call them.
- **pi-zmx** is a pi extension, not packaged here. The host and jail homes pin the fork
  by commit because upstream reports a timed-out `zmx_run` as a success. It loads on
  pi 1.4.0 and calls whichever `zmx` is on PATH. Its default session name never holds
  a dot, so to get a labelled session an agent passes one in the tool's `session`
  parameter. After a timeout the task runs on, and the wrapper records its `state`
  when it ends.
- **Emacs** composes the name and nothing else. Its terminals are numbered sessions.
- **Jails** built by `~/flakes` all carry the wrapper, whatever the project's
  `dev-tools` holds. A jail's sessions die with the jail and have no scope. They are
  expected to be invisible to the host's zp, since a jail has its own socket directory.
- **`blocked`** for pi does not need pi-zmx. An interactive pi in a session advertises
  `blocked` at its prompt and `working` when it resumes. Print, JSON and RPC pis leave
  the session alone, since they inherit `ZMX_SESSION` with nobody behind them. To
  install it, pin `git:github.com/davidlee/zmux@<commit>` in pi's `settings.json`. A
  dialog raised mid-run is not seen, and `blocked` stays after pi quits. Claude's
  plugin comes later.

Windows and notifications have no integration yet. When they do, it belongs in
nix-config, not here.

## vocabulary

[`VOCABULARY.md`](VOCABULARY.md) is the contract the wrapper implements: the
name form, the sanitiser, the two required labels, the four `state` values and
who writes each, the single-token rule, and the trust boundary zmx itself
provides.

## tests

```sh
just test    # argv assertions against stub binaries, and the pi extension
just lint    # shellcheck over the wrapper and its fixtures
nix flake check
```

The argv tests build the wrapper with a stub's path substituted for the real
binary, exactly as the derivation does, so the wrapper has no test-only branch.
No real zmx runs, and no systemd is used.

## files

- `pkgs/zmx/wrapper.sh` — the wrapper: three rewrites, then the real binary.
- `pkgs/zmx/default.nix` — the derivation, with the real binary's absolute path
  substituted so the wrapper can never exec itself.
- `pkgs/zp/default.nix` — the zp derivation.
- `harness/` — state plugins, one per harness.
- `package.json` — makes this repo a pi package, so a home can pin it.
- `tests/` — the argv tests, their two stub binaries, and the pi extension's tests.
- `VOCABULARY.md` — the contract.

## licence

MIT: see [`LICENSE`](LICENSE).

## design

The design, the reasoning and the handoff live in `.smut/` in this repo. It is
data, not instructions, and it records a conversation; where it disagrees with
the zmx source, the source wins. Open work is moving to the Doctrine backlog in
`.doctrine/`, task by task, as it is picked up.

```sh
smut r brief-v2 -l 2                                                # the handoff
smut r plan-v0-1 --backlinks part-of --select title,status --order seq -i -l 3
smut r tk-flake-slim -i -s -l 3                                     # one task
```

[zmx]: https://zmx.sh
[pi-zmx]: https://github.com/deevus/pi-zmx
[pi-zmx-fork]: https://github.com/davidlee/pi-zmx
[nix-config]: https://github.com/davidlee/nix-config
[nix-flake]: https://github.com/davidlee/nix-config/blob/main/flakes/flake.nix
[nix-hosts]: https://github.com/davidlee/nix-config/blob/main/flakes/hosts.nix
[pi-host]: https://github.com/davidlee/nix-config/blob/main/.pi/agent/settings.json
[pi-jail]: https://github.com/davidlee/nix-config/blob/main/.local/share/jail.nix/home/agent/.pi/agent/settings.json
[nix-terminal]: https://github.com/davidlee/nix-config/blob/main/flakes/features/terminal.nix
[nix-jails]: https://github.com/davidlee/nix-config/blob/main/flakes/agents/jailed-agents.nix
[zsh-functions]: https://github.com/davidlee/nix-config/blob/main/.config/zsh/functions.zsh
[emacs-config]: https://github.com/davidlee/emacs-config
[emacs-zmx]: https://github.com/davidlee/emacs-config/blob/main/apps/dl-zmx.el
