# Vocabulary

What a zmx session name and its labels mean. The wrapper writes the labels, so
this page is the contract it implements. Sources: `d-name-form`, `d-vocab`,
`d-state-writer`, `d-naming` in `.smut/`.

## Name

    <project>.<id>

The first dot separates project from id, and nothing else does. The split is
unambiguous, which is the only place a name has to be unambiguous: a human
reading `zmx ls`.

Deriving the labels from the name a caller gives:

1. Split at the first dot. A name with no dot is **undotted**: it gets no
   labels and returns no project. Ungrouped and honest beats grouped and wrong.
2. In each part, replace every character outside `[a-zA-Z0-9_-]` with `-`.
   A dot at this point is inside a part — the separator was consumed by step 1 —
   so it becomes `-` as well.
3. A part that sanitises to nothing is refused (exit 2). An empty `project=` or
   `id=` would delete a label rather than write one, and a name that has to be
   rewritten is refused rather than retargeted. A leading dot is therefore an
   empty project, not a hidden one.

The caller's name is passed to zmx unchanged. Labels are derived from it; where
the two disagree, the labels are the truth.

## Labels

Two required, one interpreted, everything else freeform.

| key       | written by                                        | values                                                  |
| --------- | ------------------------------------------------- | ------------------------------------------------------- |
| `project` | the dispatcher, once, at creation                 | the first name part, sanitised                          |
| `id`      | the dispatcher, once, at creation                 | the second name part, sanitised                         |
| `state`   | the dispatcher, around a dispatch                 | `working`, `done`, `failed`, `blocked`; absent = unknown |

### project, id

Written together on the one `zmx attach` call that creates the session. Labels
are create-time only, so there is no later repair: a session created outside the
convention stays ungrouped forever, and is displayed ungrouped. An existing
session is never relabelled.

### state

`state` is intent. zmx's own `ended` and `exit_code` are fact. A session can
claim `working` while its task has ended; a reader shows both and believes
neither alone.

- `working` — written before work is handed to the session. Left in place when
  the dispatch was detached, because the work has not returned.
- `done`, `failed` — written when a synchronous task returns 0, or non-zero.
- `blocked` — written by the program inside the session, or by the harness that
  is asking a human to attach. Never inferred; nothing can know a human is
  wanted.
- absent — unknown. Displayed as unknown, never as idle.

Ordering, where a reader needs one: `blocked`, `working`, `done`/`failed`,
unknown.

Only one delete is allowed: on attach, a human may clear `state=blocked`,
because the human arriving is the event that unblocks it. Nothing else deletes a
label, and nothing watches.

A stale state costs nothing: it is an advertisement, not a lock.

### freeform

Any other key — `role`, `note`, `claim`, a tag board — is stored, displayed and
counted, never reasoned about. A new key costs nothing; a new *interpreted* key
must earn a reader.

## Tokens

Keys and values are single tokens from `[a-zA-Z0-9._-]`. zmx refuses the
characters outside that set, but a space inside a value is not an error: it ends
the value and silently drops the rest, so `note=hello world` stores
`note=hello`. Prose therefore belongs in session history, not in a label.

Lowercase keys and values. zmx prints labels in ASCII order, so all-lowercase
keeps `zmx get` and `zmx ls` predictable.

One fact, one home: never repeat `state` in the name, and never re-derive
`project` from the name once the label exists.

Labels live in memory for the session's lifetime. They vanish with the session.

## Trust

One user, or a group that shares a socket directory. zmx authenticates nothing:
`ZMX_DIR_MODE` and `ZMX_LOG_MODE` make a session attachable, writable and
relabelled by anyone the permission bits admit. So a label is a claim, not
proof — `state=blocked` means someone said so — and no secret belongs in one.
