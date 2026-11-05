The `done` wrinkle: pi-zmx creates a session with `zmx run NAME true`, which the wrapper
brackets as `working` then `done`. The claim is true, since a trivial task did complete.
Deciding what counts as real work would turn the wrapper into a heuristic.

## Changed from the source

Smut `d-install` put the raw binary at `${pkgs.zmx}/bin/zmx`; see DEC-007.
