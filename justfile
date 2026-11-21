# argv assertions against stub binaries, and the harness hooks against fakes:
# no real zmx, no real systemd, no real pi, no real Claude Code.
test:
    ./tests/run-tests.sh
    node --test tests/zmx-state.test.ts tests/zmx-state-command.test.ts tests/claude-state.test.ts tests/codex-state.test.ts

# Shell hygiene for the wrapper and its fixtures.
lint:
    shellcheck pkgs/zmx/wrapper.sh pkgs/zmx-new/zmx-new.sh pkgs/zmx-state/zmx-state.sh tests/run-tests.sh tests/stubs/zmx tests/stubs/systemd-run tests/stubs/harness harness/claude/zmx-state.sh harness/codex/zmx-state.sh harness/advertise.sh

# Approving is a separate, deliberate act: the report never writes.
# Relink this checkout's quotient forms, then report what `quotient allow` needs.
forms:
    ~/flakes/bin/dev-envs-forms
    quotient allow

# Pin the homes to this checkout's HEAD: push it, re-lock ~/flakes/agents onto it,
# commit and push that lock, then re-lock agents in ~/flakes. The root lock is left
# for you to rebuild from and commit, as `just upgrade` does after verifying.
# Refuses a dirty or unpushable lock, which would ride along.
flakes := env("FLAKES", home_directory() / "flakes")

[script("bash")]
ship:
    set -euo pipefail
    agents='{{ flakes }}/agents'
    for dir in '{{ flakes }}' "$agents"; do
      git -C "$dir" diff --quiet HEAD -- flake.lock ||
        { echo "ship: $dir/flake.lock has uncommitted changes" >&2; exit 1; }
    done
    git push -q
    (cd "$agents" && nix flake update zmux)
    if ! git -C "$agents" diff --quiet HEAD -- flake.lock; then
      git -C "$agents" commit -q -m "chore(agents): bump zmux to $(git rev-parse --short HEAD)" -- flake.lock
    fi
    git -C "$agents" push -q
    (cd '{{ flakes }}' && nix flake update agents)
    echo "ship: rebuild home (just home-switch in {{ flakes }}), then commit its flake.lock" >&2
