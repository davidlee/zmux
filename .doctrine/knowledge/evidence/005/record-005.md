## Method

The wrapper from `pkgs/zmx/wrapper.sh` over zmx 0.8.1, with ghostel from the Emacs config,
in batch Emacs on x86_64-linux, 2026-11-06, with a scratch `ZMX_DIR`. Each case went through
`dl-zmx--open`, which runs `ghostel-exec` on `zmx attach NAME sh`.

| Name | `ghostel-kill-buffer-on-exit` | Observed |
|---|---|---|
| `doctrine.v0.1` | `t` | process ends within 0.21s, buffer gone |
| `doctrine.v0.2` | `nil` | buffer stays and holds the wrapper's message |
| `.1` | `t` | process ends within 0.21s, buffer gone |

Outside Emacs, both names exit 2 with that message. `ghostel--sentinel` kills the buffer when
the variable is set. The live `emacs.service` daemon has it `t`, and neither `apps/`, `core/`
nor `custom-vars.el` sets it.

After the fix (emacs ISS-013), the same harness gave a `user-error` for a new dotted
identifier, and for `my/zmx-new` and `my/zmx-resume` at `/`. A session created as
`probeproj.v0.1` with real `zmx run` opened through `my/zmx-project` with a live process.

## What it means

A caller that relies on the wrapper's refusal reaching a person through a ghostel buffer
gets nothing readable. Emacs has to refuse before it attaches.

## Not established

Whether a person sees the buffer flash in a graphical frame. Batch Emacs has no display, so
the 0.21s is a timing from this harness, not from a live window.
