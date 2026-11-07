# argv assertions against stub binaries, and the harness hooks against fakes:
# no real zmx, no real systemd, no real pi, no real Claude Code.
test:
    ./tests/run-tests.sh
    node --test tests/zmx-state.test.ts tests/zmx-state-command.test.ts tests/claude-state.test.ts tests/codex-state.test.ts

# Shell hygiene for the wrapper and its fixtures.
lint:
    shellcheck pkgs/zmx/wrapper.sh pkgs/zmx-new/zmx-new.sh tests/run-tests.sh tests/stubs/zmx tests/stubs/systemd-run tests/stubs/harness harness/claude/zmx-state.sh harness/codex/zmx-state.sh harness/advertise.sh

# Approving is a separate, deliberate act: the report never writes.
# Relink this checkout's quotient forms, then report what `quotient allow` needs.
forms:
    ~/flakes/bin/dev-envs-forms
    quotient allow
