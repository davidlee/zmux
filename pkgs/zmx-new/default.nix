# The launcher: a caller of the wrapper, so the wrapper it reaches is whichever
# this package set calls zmx, addressed by absolute path. As for the wrapper, the
# script keeps its own `#!/bin/sh` and adds nothing to the caller's PATH.
{
  runCommand,
  zmx,
}:
runCommand "zmx-new" {meta.mainProgram = "zmx-new";} ''
  mkdir -p "$out/bin"
  substitute ${./zmx-new.sh} "$out/bin/zmx-new" --replace-fail '@zmx@' '${zmx}/bin/zmx'
  chmod +x "$out/bin/zmx-new"
''
