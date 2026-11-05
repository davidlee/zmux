{
  description = "zmux: a zmx with opinions — the wrapper, its argv tests and the Emacs plugin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
    agents = {
      url = "github:davidlee/nix-config?dir=flakes/agents";
    };
    # quotient's form-family builder, for quotientForms below.
    quotient = {
      url = "github:davidlee/quotient/v0.6.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }: let
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
        inherit (pkgs.stdenv.hostPlatform) isLinux;

        jailLib =
          if isLinux
          then inputs.agents.lib.${system}.mkJailedAgents {}
          else {};

        agents = lib.optionalAttrs isLinux jailLib.agentsByName;

        # -- Customise these for the project --

        devToolPkgs = with pkgs; [
          just
          shellcheck
          # The wrapper's argv tests are shell; these are what they call.
          bash
          coreutils
          findutils
          diffutils
          gnused
        ];

        projectPkgs =
          devToolPkgs
          ++ (with pkgs; [
            # Through the overlay, so this is the wrapper: anything that calls
            # `zmx` here — a test, zp, pi-zmx — gets labels and a scope.
            zmx
            (agents.codex or codex) # mcp server slave — llm-agents build on linux
          ]);

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

        # Sibling repos to bind-mount (for editable deps / source inspection).
        # Each path appears at /workspace/<basename> inside the jail; a host
        # symlink like ./some-lib -> ../some-lib resolves correctly.
        # workspaceDeps bind read-only; list a dep the agents must write in
        # workspaceDepsRw instead. Machine-local additions: the .envrc's
        # JAIL_WORKSPACE_DEPS and JAIL_WORKSPACE_DEPS_RW.
        workspaceDeps = [
          "/home/david/flakes"
        ];

        workspaceDepsRw = [
          # "/home/you/notes"
        ];

        # Interactive jails (`jailed-claude`, ...): the cwd at
        # /workspace/deck_of_dwarf, a persisted home, network on, SSH push
        # blocked.
        # smutPath = "\"$HOME/.cargo/bin/smut\"";
        # smutOptions = with jailLib.combinators; [
        #   (try-ro-bind (noescape "~/.cargo/bin/smut") (noescape smutPath))
        #   (add-path smutPath)
        # ];
        # bwrap starts with a clean env. Forward / set what agents need.
        # Combinators: set-env, fwd-env (error if unset), try-fwd-env (skip if unset),
        # try-readwrite (bind a host path rw if it exists).
        jailEnvOptions = lib.optionals isLinux (with jailLib.combinators; [
          # pulse # opt-in host audio; uses $XDG_RUNTIME_DIR
          # (try-readonly "/path/on-this-host/notification.wav")
          # (try-fwd-env "DATABASE_URL")
          # (try-fwd-env "DOCKER_HOST")
          # (try-readwrite "/path/to/docker.sock")
          # (set-env "CGO_ENABLED" "0")
        ]);

        # Every jail reaches models through the local LLM gateway with the shared
        # `pi` key (~/.config/llm-gateway/keys/pi); no provider key enters a jail.
        # It is the only model access (agents/README.md § Model access).
        gateway = jailLib.gatewayClient "pi";

        # -- Agents --
        #
        # Profiles:
        #   specDev   — shared persistent home, network on, SSH push blocked, sandboxed identity
        #   research  — separate persistent home, network on, SSH push blocked, host identity
        #   offline   — separate persistent home, no network
        #
        # Extra per-agent knobs (all optional):
        #   exposePostgres       = true;   # bind /run/postgresql into the jail
        #   blockSshGitPush      = false;  # SSH only; HTTPS remains available
        #   allowSelfAsSubagent  = true;   # let agent recursively spawn itself
        #   maxSubagentDepth     = 2;      # cap recursion depth (default 1)
        #   gateway              = null;   # no model, unless the agent signs in itself

        jailPkgs = lib.optionalAttrs isLinux {
          jailed-pi = jailLib.makeJailedPi {
            profile = "specDev";
            allowSelfAsSubagent = true;
            maxSubagentDepth = 2;
            extraPkgs = projectPkgs;
            extraOptions = jailEnvOptions;
            inherit gateway workspaceDeps workspaceDepsRw;
          };

          jailed-pi-research = jailLib.makeJailedPi {
            name = "pi-research";
            profile = "research";
            extraPkgs = projectPkgs;
            extraOptions = jailEnvOptions;
            inherit gateway workspaceDeps workspaceDepsRw;
          };

          jailed-claude = jailLib.makeJailedClaude {
            profile = "specDev";
            extraPkgs = projectPkgs;
            extraOptions = jailEnvOptions;
            inherit gateway workspaceDeps workspaceDepsRw;
          };

          jailed-shell = jailLib.makeJailedAgent {
            name = "shell";
            agent = pkgs.zsh;
            extraPkgs = projectPkgs;
            subagents = ["pi" "claude"];
          };

          inherit (pkgs) bubblewrap;
        };

        # quotient's per-call forms for this root (`quotient help form`): the
        # jails quotient's `pi_agent` runs a delegate in, on the gateway's pi
        # key, with the project's toolchain.
        quotientForms = lib.optionalAttrs isLinux (let
          family = jailLib.quotientFormFamily {
            inherit (inputs) quotient;
            packages =
              projectPkgs
              ++ (with pkgs; [
                bash
                findutils
                gnugrep
                gnused
                gawk
                ripgrep
                fd
                git
                socat
                # netscan
              ]);
          };
        in {
          quotient-read = family.read;
          quotient-write = family.write;
        });
      in {
        _module.args.pkgs = pkgs;

        packages =
          jailPkgs
          // quotientForms
          // {
            default = pkgs.zmx;
            zmx = pkgs.zmx;
            zp = pkgs.zp;

            dev-tools = pkgs.buildEnv {
              name = "zmux-dev-tools";
              paths = devToolPkgs;
            };
          };

        # `nix flake check` builds the package and runs the wrapper's tests on
        # every declared system.
        checks = {
          zmx = pkgs.zmx;
          wrapper-tests = wrapperTests;
          wrapper-lint = wrapperLint;
          wrapper-parity = wrapperParity;
          zp-uses-wrapper = zpUsesWrapper;
        };

        devshells.default = {
          packages =
            projectPkgs
            ++ lib.optionals isLinux (lib.attrValues jailPkgs);

          # The plugin, for an Emacs on the host: (add-to-list 'load-path
          # (getenv "DL_ZMX_ELISP")). It is not vendored into any package here —
          # integrations live in the config repo (d-surfaces).
          env = [
            {
              name = "DL_ZMX_ELISP";
              value = "${./emacs}";
            }
          ];

          commands = [
            {
              name = "jcl";
              help = "jailed-claude --dangerously-skip-permissions";
              command = "jailed-claude --dangerously-skip-permissions $@";
            }
            {
              name = "quotient-forms";
              help = "link .quotient/forms/{read,write}; then `quotient allow`";
              command = ''
                mkdir -p .quotient/forms
                for c in read write; do
                  nix build -o ".quotient/result-$c" ".#quotient-$c"
                  ln -sfn "$(readlink -f ".quotient/result-$c")/bin/quotient-$c" ".quotient/forms/$c"
                done
              '';
            }
          ];
        };
      };
    };
}
