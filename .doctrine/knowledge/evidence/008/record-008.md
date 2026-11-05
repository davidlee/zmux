## Method

Reprobed 2026-11-06, zmx 0.8.1, scratch `ZMX_DIR`. A script printed
`\033]7501;state=blocked;app=probe\033\\` then `AFTER_OSC`, run with `zmx run NAME sh FILE`.
`history` and `history --vt` held no `7501`, and both held `AFTER_OSC`. zmx's own
`ZMX_TASK_COMPLETED:<token>:$?` marker stays, because it is plain text.

The script has to be a file: `zmx run` echoes a typed command into history.

## Consequence

herdr-style status can't be read back out of zmx. A label needs the same cooperation from the
program, with no protocol and no parser (DEC-003).
