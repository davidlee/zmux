# The wrapped zmx (d-wrapper): the package *is* the wrapper, so installing it by
# overlay changes behaviour declaratively and reverts in one line. The real
# binary is addressed by absolute path, substituted into the script, so the
# wrapper can never re-enter itself and stays upgradeable as `${pkgs.zmx}`.
#
# writeScriptBin, not writeShellScriptBin or writeShellApplication: the script
# carries its own `#!/bin/sh`, and neither a pinned PATH nor an injected
# shebang line belongs in a wrapper whose whole job is to leave the caller's
# environment alone.
{
  writeScriptBin,
  zmx,
}:
writeScriptBin "zmx" (
  builtins.replaceStrings
  ["@zmx@"]
  ["${zmx}/bin/zmx"]
  (builtins.readFile ./wrapper.sh)
)
