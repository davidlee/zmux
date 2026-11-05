# argv assertions against stub binaries: no real zmx, no real systemd.
test:
    ./tests/run-tests.sh

# Shell hygiene for the wrapper and its fixtures.
lint:
    shellcheck pkgs/zmx/wrapper.sh tests/run-tests.sh tests/stubs/zmx tests/stubs/systemd-run

# Approving is a separate, deliberate act: the report never writes.
# Relink this checkout's quotient forms, then report what `quotient allow` needs.
forms:
    ~/flakes/bin/dev-envs-forms
    quotient allow
