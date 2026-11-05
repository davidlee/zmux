# Vocabulary

What a zmx session name and its labels mean. The wrapper writes the labels, so
this page is the contract it implements. Sources: `d-name-form`, `d-vocab`,
`d-state-writer`, `d-naming` in `.smut/`.

## Name

    <project>.<id>

One dot separates project from id, and a name holds no other. The split is
unambiguous, which is the only place a name has to be unambiguous: a human
reading `zmx ls`.

Deriving the labels from the name a caller gives:

1. A name with no dot is **undotted**: it gets no labels and returns no project.
   Ungrouped and honest beats grouped and wrong.
2. A name with more than one dot, or with nothing on one side of its dot, is
   refused (exit 2). A second dot leaves the project ambiguous: `my.repo.1` could
   only be grouped under `my`. An empty `project=` or `id=` would delete a label
   rather than write one. A leading dot is therefore an empty project, not a
   hidden one. A caller whose project holds a dot folds it to `_` first.
3. Split at the dot. In each part, replace every character outside
   `[a-zA-Z0-9_-]` with `-`. Case is kept: a project is spelled as its directory
   is, so `Zmux.1` and `zmux.1` are two projects.

Refusal is a rule of creation. An existing session with such a name stays
reachable, and the wrapper leaves it unlabelled.

The caller's name is passed to zmx unchanged, and labels are derived from it. The
name is the address: every zmx verb selects a session by name, and none by label.
Labels describe the session: where the two disagree, the labels are the truth for
grouping and display.

## Labels

Two required, one interpreted, one for display, everything else freeform.

| key       | written by                                        | values                                                  |
| --------- | ------------------------------------------------- | ------------------------------------------------------- |
| `project` | the dispatcher, once, at creation                 | the first name part, sanitised                          |
| `id`      | the dispatcher, once, at creation                 | the second name part, sanitised                         |
| `state`   | the dispatcher, or the harness for `blocked`      | `working`, `done`, `failed`, `blocked`; absent = unknown |

### project, id

Written together, only when the wrapper creates the session. `zmx attach` writes
them atomically with `--labels`. `zmx run` takes no labels, so it creates the
session and then calls `zmx set`; a wrapper that dies between the two leaves an
unlabelled session.

The wrapper never relabels an existing session, so one created outside the
convention stays ungrouped, and is displayed ungrouped. zmx itself allows `zmx
set` at any time, so that is a rule of the wrapper, not a limit of zmx.

These meanings are the wrapper's, not zmx's. `zmx set` accepts any value for either
key, even `id=other.thing` on an undotted session, so a reader treats them as claims.

### state

`state` is intent. zmx's own `ended` and `exit_code` are fact. A session can
claim `working` while its task has ended; a reader shows both and believes
neither alone.

- `working` — written before work is handed to the session. Left in place when
  the dispatch was detached, because the work has not returned.
- `done`, `failed` — written when a synchronous task returns 0, or non-zero. That
  holds if the caller is terminated mid-run, unless the whole process group is.
- `blocked` — written by the program inside the session, or by the harness that
  is asking a human to attach. Never inferred; nothing can know a human is
  wanted. For pi, `harness/pi/zmx-state.ts` writes it at the prompt, and `working`
  when pi resumes.
- absent — unknown. Displayed as unknown, never as idle.

Ordering, where a reader needs one: `blocked`, `working`, `done`/`failed`,
unknown.

Only one delete is allowed: on attach, a human may clear `state=blocked`,
because the human arriving is the event that unblocks it. Nothing else deletes a
label, and nothing watches.

A stale state costs nothing: it is an advertisement, not a lock.

### role

One token saying what a session is for, for a purpose that emerges after the name was
chosen. A session can't be renamed, so `docs.2` stays `docs.2`:

    zmx set docs.2 role=test-runner

Pickers show `role` if present. Nothing reasons about it, so it stays freeform. Use
hyphens: `'role=test runner'` silently stores `role=test` (see [Tokens](#tokens)).

### freeform

Any other key — `note`, `claim`, a tag board — is stored, displayed and
counted, never reasoned about. A new key costs nothing; a new *interpreted* key
must earn a reader.

## Tokens

Keys and values are single tokens from `[a-zA-Z0-9._-]`. zmx refuses the
characters outside that set, but a space inside a value is not an error: it ends
the value and silently drops the rest, so `note=hello world` stores
`note=hello`. Prose therefore belongs in session history, not in a label.

Lowercase keys, and lowercase `state` values. zmx prints labels in ASCII order, so
all-lowercase keys keep `zmx get` and `zmx ls` predictable. `project` and `id` keep
the case of the name.

One fact, one home: never repeat `state` in the name, and never re-derive
`project` from the name once the label exists.

Labels live in memory for the session's lifetime. They vanish with the session.

`zmx list` prints labels as tab-separated fields beside zmx's own. A filter must match
whole fields: `grep id=3` also matches `pid=3…`.

## Trust

One user, or a group that shares a socket directory. zmx authenticates nothing:
`ZMX_DIR_MODE` and `ZMX_LOG_MODE` make a session attachable, writable and
relabelled by anyone the permission bits admit. So a label is a claim, not
proof — `state=blocked` means someone said so — and no secret belongs in one.
