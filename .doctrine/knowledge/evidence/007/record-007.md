# EVD-007: Sessions from zp, Emacs and pi survive emacs.service and WM restarts

<!-- Knowledge record body — context, detail, links. The structured, queried
     fields live in the sister `record-NNN.toml`; this prose is free-form and is
     never structurally parsed (the storage rule). -->

## Method

Operator's restarts on Sleipnir, x86_64-linux, 2026-11-06: `emacs.service` at 08:44:39 and
`umbriel.service` at 08:46:34, by systemd's `ActiveEnterTimestamp`. The live `ZMX_DIR`, read
only: `zmx ls`, `/proc/<pid>/cgroup`, process start times and `zmx history`.

| Session | Created by | Started | pid | Scope | Scrollback |
|---|---|---|---|---|---|
| `hostcheck.zp` | zp | 08:32:49 | 2325418 | `run-p2325409-i6465120` | `zp-marker` present |
| `hostcheck.pi` | `zmx attach`, running pi | 08:33:51 | 2327377 | `run-p2327368-i6586817` | present; `state=blocked` |
| `emacs.emacs` | Emacs | 08:35:55 | 2329400 | `run-p2329390-i6536640` | the 08:40 command present |

The two `hostcheck` rows were identical in the operator's before and after snapshots.
`emacs.emacs` was not in those snapshots: its start time predates both restarts, and its
pid is unchanged since. Its scrollback shows a prompt stamped 08:45, after the Emacs restart.

Reported by the operator after both restarts: all three reattached and pi answered a new
prompt. In an Emacs terminal, with `nu` inside zmx, `default-directory` followed `cd`, and
shell integration worked. Scrollback in the buffer was barely exercised, since these
sessions held little output: the operator counts it as passing from general use of zmx.

## Detach and reattach in Emacs

Operator's check on Sleipnir, 2026-11-06. The first attempt failed: `C-c m t` stopped at
`Ghostel: directory kitty-shell-cwd://Sleipnir/home/david/dev/zmux/ does not exist`, because
`dl-zmx--session-dir` only understood `file://`. Ghostel's zsh and bash integrations report
`kitty-shell-cwd://`. Fixed in `apps/dl-zmx.el` in the Emacs config, with a test.

After the fix, the operator reported a pass on a zsh session started with `C-c m T`: after
`cd /tmp`, killing the buffer detached and `C-c m t` reattached to the same session in
`/tmp`, and `seq 1 5000` output survived the reattach in scrollback. How far back
scrollback reaches was not reported.
