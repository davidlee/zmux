# The wrapped zmx (d-wrapper): the package *is* the wrapper, so installing it by
# overlay changes behaviour declaratively and reverts in one line. It is the
# package it shadows with one file replaced, so completions, version and meta
# carry over. The real binary is addressed by absolute path, substituted into
# the script, so the wrapper can never re-enter itself and stays upgradeable as
# `${pkgs.zmx-unwrapped}`.
#
# No shebang patching and no pinned PATH: the script carries its own `#!/bin/sh`,
# and a wrapper whose whole job is to leave the caller's environment alone adds
# nothing to it.
{
  symlinkJoin,
  zmx,
}:
symlinkJoin {
  name = "zmx-${zmx.version}";
  inherit (zmx) version meta;
  paths = [zmx];
  postBuild = ''
    rm "$out/bin/zmx"
    substitute ${./wrapper.sh} "$out/bin/zmx" --replace-fail '@zmx@' '${zmx}/bin/zmx'
    chmod +x "$out/bin/zmx"
  '';
}
