# EVD-001: zmx ended reports the last task, not the session

<!-- Knowledge record body — context, detail, links. The structured, queried
     fields live in the sister `record-NNN.toml`; this prose is free-form and is
     never structurally parsed (the storage rule). -->

## Method

zmx 0.8.1, unwrapped, on x86_64-linux, 2026-11-06, with a scratch `ZMX_DIR`.

| Step | Observed |
|---|---|
| `zmx run e.1 true`, then `zmx list` | `ended=` and `exit_code=0` present, and `kill -0` on the listed pid succeeds |
| `zmx attach e.1` in a pty, send `echo PROBE_$((40+2))` | `PROBE_42` printed, so a shell evaluated it |
| `exit` in that shell | the session leaves `zmx list` |
| `zmx run e.2 true`, then `zmx run e.2 sleep 3 -d` | `ended` absent while the task runs, present once it finishes |
| `zmx kill e.2` | the session leaves `zmx list` |
| `zmx attach a.1 sh -c 'sleep 1'`, command exits | the session is not listed afterwards |

A long-lived session on the host showed the same thing: `ended` and `exit_code=0`
listed, with `bash` alive at the listed pid.

## What it means

`ended` must not be read as "the session is gone". Every session the wrapper creates
through `zmx run` starts with a `true` task, so it carries `ended` until the next task
runs. This agrees with `VOCABULARY.md`, where `ended` and `exit_code` are the task's
facts beside `state`.

`dl-zmx--parse-sessions` in the Emacs config (`apps/dl-zmx.el`) used to treat `ended` as
an exited session and skip it, which hid live sessions. This finding removed that.

## Not established

Whether a session started by `zmx attach NAME` with no command behaves differently
when a later `zmx run` task ends. Only the `zmx run` path was tested.
