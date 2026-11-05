Recorded by 2026-11-03: no `systemd-run`, `systemctl` or `busctl`, `/proc/1` is
bwrap, pid and cgroup are unshared, and it runs with `--die-with-parent`. `README.md` still
states the consequence. The jail's flags were not rechecked.

This is why the launcher is data, and why `tests/run-tests.sh` runs with no real zmx and no
systemd. The manual host checks are EVD-004, EVD-007 and EVD-013.
