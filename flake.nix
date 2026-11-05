{
  description = "zmux: a zmx with opinions — the wrapper, its argv tests and the Emacs plugin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
  };

  outputs = inputs @ {flake-parts, ...}: let
    # The delivery mechanism (d-install): the wrapper *is* the package, so an
    # overlay makes every caller conform without knowing it. The binary it
    # shadows keeps its own name, unforked and upgradeable — that is the escape
    # hatch that makes shadowing a convention rather than a trap.
    overlay = final: prev: {
      zmx-unwrapped = prev.zmx;
      zmx = final.callPackage ./pkgs/zmx {zmx = final.zmx-unwrapped;};
      zp = final.callPackage ./pkgs/zp {};
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devshell.flakeModule
      ];

      flake.overlays.default = overlay;

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      perSystem = {system, ...}: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [overlay];
        };

        inherit (pkgs) lib;
        # -- Customise these for the project --

        # The producer contract with ~/flakes/dev-envs: every jail, form and
        # shell there is built from `dev-tools`, this flake's only tie to them.
        devToolPkgs = with pkgs; [
          # Through the overlay, so this is the wrapper: anything that calls
          # `zmx` here — a test, zp, pi-zmx — gets labels and a scope.
          zmx
          just
          shellcheck
          # The wrapper's argv tests are shell; these are what they call.
          bash
          coreutils
          findutils
          diffutils
          gnused
        ];

        devTools = pkgs.buildEnv {
          name = "zmux-dev-tools";
          paths = devToolPkgs;
        };

        # -- The package --
        #
        # The wrapper, not a build: this repo ships a shell script installed as
        # `zmx` (d-wrapper). It arrives through the overlay above, so
        # `pkgs.zmx` is the wrapper and `pkgs.zmx-unwrapped` the binary.

        # The argv tests and the lint, as `nix flake check` sees them. The
        # wrapper under test is substituted by the harness itself, so these run
        # with no real zmx and no systemd (c-devjail).
        wrapperSrc = lib.fileset.toSource {
          root = ./.;
          fileset = lib.fileset.unions [
            ./pkgs/zmx
            ./tests
          ];
        };

        wrapperTests =
          pkgs.runCommand "zmx-wrapper-tests" {
            nativeBuildInputs = with pkgs; [
              bash
              coreutils
              findutils
              diffutils
              gnused
            ];
          } ''
            cp -r ${wrapperSrc} source
            bash source/tests/run-tests.sh > "$out"
          '';

        wrapperLint =
          pkgs.runCommand "zmx-wrapper-lint" {
            nativeBuildInputs = [pkgs.shellcheck];
          } ''
            shellcheck ${./pkgs/zmx/wrapper.sh} ${./tests/run-tests.sh} \
              ${./tests/stubs/zmx} ${./tests/stubs/systemd-run}
            touch "$out"
          '';

        # Shadowing must cost a caller nothing but the rewrites: whatever the
        # unwrapped package ships, the wrapper ships too.
        wrapperParity = pkgs.runCommand "zmx-wrapper-parity" {} ''
          cd ${pkgs.zmx-unwrapped}
          find share -type f,l | while read -r file; do
            test -e "${pkgs.zmx}/$file" || {
              echo "missing from the wrapper: $file" >&2
              exit 1
            }
          done
          grep -q '^REAL_ZMX=.${pkgs.zmx-unwrapped}/bin/zmx.$' ${pkgs.zmx}/bin/zmx
          test "${pkgs.zmx.version}" = "${pkgs.zmx-unwrapped.version}"
          touch "$out"
        '';

        # zp creates sessions by calling `zmx`, so it only inherits the convention
        # if the `zmx` it finds is the wrapper.
        zpUsesWrapper = pkgs.runCommand "zp-uses-wrapper" {} ''
          ${pkgs.zp}/bin/zp --help > /dev/null
          grep -qF '${pkgs.zmx}/bin' ${pkgs.zp}/bin/zp
          touch "$out"
        '';

        # A jail's tools are dev-tools, so pi-zmx only finds `zmx` in a jail if
        # dev-tools carries it, and only conforms if that `zmx` is the wrapper.
        devToolsShipWrapper = pkgs.runCommand "dev-tools-ship-wrapper" {} ''
          cmp ${devTools}/bin/zmx ${pkgs.zmx}/bin/zmx
          touch "$out"
        '';
      in {
        _module.args.pkgs = pkgs;

        packages = {
          inherit (pkgs) zmx zp;
          default = pkgs.zmx;
          dev-tools = devTools;
        };

        # `nix flake check` builds the package and runs the wrapper's tests on
        # every declared system.
        checks = {
          inherit (pkgs) zmx;
          wrapper-tests = wrapperTests;
          wrapper-lint = wrapperLint;
          wrapper-parity = wrapperParity;
          zp-uses-wrapper = zpUsesWrapper;
          dev-tools-ship-wrapper = devToolsShipWrapper;
        };

        devshells.default = {
          packages = devToolPkgs;

          # The plugin, for an Emacs on the host: (add-to-list 'load-path
          # (getenv "DL_ZMX_ELISP")). It is not vendored into any package here —
          # integrations live in the config repo (d-surfaces).
          env = [
            {
              name = "DL_ZMX_ELISP";
              value = "${./emacs}";
            }
          ];
        };
      };
    };
}
