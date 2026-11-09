# zp, the picker (DEC-011): upstream's script, from our fork while two changes
# wait upstream (IMP-010): `ZP_LABEL_MARKS`, and the `local +x out` fix in
# daemon_pid. Return to an upstream tag once they ship. Its `zmx` is whatever
# this package set calls zmx, which under the overlay is the wrapper, so sessions
# created from zp get labels and a scope. jj stays optional, found on the
# caller's PATH if it is there.
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  bash,
  coreutils,
  expect,
  fd,
  fzf,
  gawk,
  git,
  gnused,
  lsof,
  procps,
  zmx,
}: let
  # A mark per `state` value (VOCABULARY.md), the icons zsh, Emacs and the harness
  # titles use (harness/advertise.sh); the caller's own setting wins.
  labelMarks = "state=working=◐ state=blocked=🔔 state=done=● state=failed=⊘";
in
  stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "zmx-picker";
    version = "0.5.0-unstable-2026-11-09";

    # Branch `zmux`: v0.5.0 plus the two commits drafted for upstream.
    src = fetchFromGitHub {
      owner = "davidlee";
      repo = "zmx-picker";
      rev = "366e3a72c2b8749af5483f22ab105c6d529c4796";
      hash = "sha256-r1fTBu8LjVW8/DFzB+nzJCPo7fdVvSC0Bs2jMn5NP+s=";
    };

    nativeBuildInputs = [makeWrapper];
    buildInputs = [bash];

    doCheck = true;
    nativeCheckInputs = [expect fzf gawk];
    checkPhase = ''
      runHook preCheck
      patchShebangs zp tests
      substituteInPlace tests/run.sh --replace-fail /bin/bash ${lib.getExe bash}
      bash tests/run.sh
      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 zp "$out/bin/zp"
      wrapProgram "$out/bin/zp" --prefix PATH : ${lib.makeBinPath [
        coreutils
        fd
        fzf
        gawk
        git
        gnused
        lsof
        procps
        zmx
      ]} \
        --set-default ZP_LABEL_MARKS ${lib.escapeShellArg labelMarks}
      runHook postInstall
    '';

    meta = {
      description = "A fuzzy finder for zmx sessions and repositories";
      homepage = "https://github.com/EarthmanMuons/zmx-picker";
      license = lib.licenses.bsd0;
      mainProgram = "zp";
    };
  })
