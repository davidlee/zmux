# zp, the picker (DEC-011): upstream's script, unforked. Its `zmx` is whatever
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
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "zmx-picker";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "EarthmanMuons";
    repo = "zmx-picker";
    tag = "v${finalAttrs.version}";
    hash = "sha256-2g78CIFURY/fMIHqwXr/p6lc3KoKaXiAgmDmzsXCAko=";
  };

  nativeBuildInputs = [makeWrapper];
  buildInputs = [bash];

  doCheck = true;
  nativeCheckInputs = [expect fzf gawk];
  checkPhase = ''
    runHook preCheck
    patchShebangs zp tests
    substituteInPlace tests/run.sh --replace-fail /bin/bash ${lib.getExe bash}
    # The builder exports $out, and zp's `local out` in daemon_pid inherits the
    # export, so the large-lsof test hands awk a >128 KiB environment (E2BIG).
    # Upstream bug; run the suite without it.
    env -u out bash tests/run.sh
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
    ]}
    runHook postInstall
  '';

  meta = {
    description = "A fuzzy finder for zmx sessions and repositories";
    homepage = "https://github.com/EarthmanMuons/zmx-picker";
    license = lib.licenses.bsd0;
    mainProgram = "zp";
  };
})
