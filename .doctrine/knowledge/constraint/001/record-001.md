`zmx --help` lists no daemon verb (checked 2026-11-06, zmx 0.8.1), so no unit can hold the
whole set. The session process outlives its client and keeps the scope alive, and the scope is
not `PartOf` the launching unit.

So zmux guarantees survival only for sessions the wrapper creates. A session created elsewhere
can be reported, from `/proc`, but not repaired. Adopting a running PID into a scope is not
assumed. EVD-007 and EVD-013 observed the survival on a host.
