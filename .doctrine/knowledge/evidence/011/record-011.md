Read from `src/ipc.zig` in neurosnap/zmx before 2026-11-03. Not re-read for this record, and
upstream may have moved on.

The header is `{tag: u8, protocol_version: u8, reserved: u16, len: u32}`, then the payload.
Tags: Input, Output, Resize, Detach, DetachAll, Kill, Info, Init, History, Run, Ack, Switch,
Write, TaskComplete, LabelGet, LabelSet, LabelClear, LabelData, Send, EnvGet, EnvSet, EnvData,
Capture, Unsupported (255).

- Switch (tag 11) moves an attached client to another session from inside one, so session
  switching needs no UI work.
- Capture (tag 22) is scoped history: the active screen plus N scrollback rows, in plain, VT or
  HTML. It is the preview primitive. `history --screen/--scrollback` exposes it on main but not
  in 0.8.1.

Speaking this from another language would be a second implementation of someone else's
unstable ABI, which is why zmux stays on the CLI (DEC-012).
