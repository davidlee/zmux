Host-side integrations are checked by hand on the host. `scope_is_usable` in
`pkgs/zmx/wrapper.sh` is the shipped form of this constraint.

## Changed from the source

Jails now carry the wrapper (`commonPkgs` in `flakes/agents/jailed-agents.nix`, per `README.md`).
A jail has its own socket directory, so its sessions are expected to be invisible to the host's
zp. Smut's list of what a jail lacks (systemd, dbus, umbriel, ghostty, notify-send) was not
rechecked.
