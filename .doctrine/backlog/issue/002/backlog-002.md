# ISS-002: A refused attach closes its Emacs buffer unread

<!-- Backlog item body — context, detail, links. The structured, queried fields
     live in the sister `backlog-NNN.toml`; this prose is free-form and is never
     structurally parsed (the storage rule). -->

Recorded in EVD-005. With `ghostel-kill-buffer-on-exit` at `t`, its default and live value,
a name the wrapper refuses (exit 2) closes its ghostel buffer in about 0.2s, so the user
never sees why. With `nil`, the buffer keeps the message.

Reproduce: `dl-zmx--open` with a name such as `doctrine.v0.1`.

The fix likely belongs in `apps/dl-zmx.el` in the Emacs config, not this repo: validate
first, or keep the buffer on a non-zero exit. If so, move this item there.
