# A host's `zmx-state`. Separate from the wrapper, and out of `dev-tools`, because a
# jail carries both and its own `zmx-state` must not be shadowed (flakes:IMP-070). It
# finds `zmx` on the caller's PATH, as the session's daemon is whatever that `zmx` is.
{runCommand}:
runCommand "zmx-state" {meta.mainProgram = "zmx-state";} ''
  install -Dm755 ${./zmx-state.sh} "$out/bin/zmx-state"
''
