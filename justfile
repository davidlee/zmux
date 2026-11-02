# argv assertions against stub binaries: no real zmx, no real systemd.
test:
    ./tests/run-tests.sh

# Shell hygiene for the wrapper and its fixtures.
lint:
    shellcheck pkgs/zmx/wrapper.sh tests/run-tests.sh tests/stubs/zmx tests/stubs/systemd-run
