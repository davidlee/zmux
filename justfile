# argv assertions against stub binaries, and the pi extension against a fake pi:
# no real zmx, no real systemd, no real pi.
test:
    ./tests/run-tests.sh
    node --test tests/zmx-state.test.ts

# Shell hygiene for the wrapper and its fixtures.
lint:
    shellcheck pkgs/zmx/wrapper.sh tests/run-tests.sh tests/stubs/zmx tests/stubs/systemd-run

# Approving is a separate, deliberate act: the report never writes.
# Relink this checkout's quotient forms, then report what `quotient allow` needs.
forms:
    ~/flakes/bin/dev-envs-forms
    quotient allow
